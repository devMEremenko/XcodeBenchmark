/*************************************************************************
 *
 * Copyright 2018 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 **************************************************************************/

#ifndef REALM_BPLUSTREE_HPP
#define REALM_BPLUSTREE_HPP

#include <realm/aggregate_ops.hpp>
#include <realm/column_type_traits.hpp>
#include <realm/decimal128.hpp>
#include <realm/timestamp.hpp>
#include <realm/object_id.hpp>
#include <realm/util/function_ref.hpp>

namespace realm {

class BPlusTreeBase;
class BPlusTreeInner;

/*****************************************************************************/
/* BPlusTreeNode                                                             */
/* Base class for all nodes in the BPlusTree. Provides an abstract interface */
/* that can be used by the BPlusTreeBase class to manipulate the tree.       */
/*****************************************************************************/
class BPlusTreeNode {
public:
    struct State {
        int64_t split_offset;
        size_t split_size;
    };

    // Insert an element at 'insert_pos'. May cause node to be split
    using InsertFunc = util::FunctionRef<size_t(BPlusTreeNode*, size_t insert_pos)>;
    // Access element at 'ndx'. Insertion/deletion not allowed
    using AccessFunc = util::FunctionRef<void(BPlusTreeNode*, size_t ndx)>;
    // Erase element at erase_pos. May cause nodes to be merged
    using EraseFunc = util::FunctionRef<size_t(BPlusTreeNode*, size_t erase_pos)>;
    // Function to be called for all leaves in the tree until the function
    // returns 'IteratorControl::Stop'. 'offset' gives index of the first element in the leaf.
    using TraverseFunc = util::FunctionRef<IteratorControl(BPlusTreeNode*, size_t offset)>;

    BPlusTreeNode(BPlusTreeBase* tree)
        : m_tree(tree)
    {
    }

    void change_owner(BPlusTreeBase* tree)
    {
        m_tree = tree;
    }

    bool get_context_flag() const noexcept;
    void set_context_flag(bool) noexcept;

    virtual ~BPlusTreeNode();

    virtual bool is_leaf() const = 0;
    virtual bool is_compact() const = 0;
    virtual ref_type get_ref() const = 0;

    virtual void init_from_ref(ref_type ref) noexcept = 0;

    virtual void bp_set_parent(ArrayParent* parent, size_t ndx_in_parent) = 0;
    virtual void update_parent() = 0;

    // Number of elements in this node
    virtual size_t get_node_size() const = 0;
    // Size of subtree
    virtual size_t get_tree_size() const = 0;

    virtual ref_type bptree_insert(size_t n, State& state, InsertFunc) = 0;
    virtual void bptree_access(size_t n, AccessFunc) = 0;
    virtual size_t bptree_erase(size_t n, EraseFunc) = 0;
    virtual bool bptree_traverse(TraverseFunc) = 0;

    // Move elements over in new node, starting with element at position 'ndx'.
    // If this is an inner node, the index offsets should be adjusted with 'adj'
    virtual void move(BPlusTreeNode* new_node, size_t ndx, int64_t offset_adj) = 0;
    virtual void verify() const = 0;

protected:
    BPlusTreeBase* m_tree;
};

/*****************************************************************************/
/* BPlusTreeLeaf                                                             */
/* Base class for all leaf nodes.                                            */
/*****************************************************************************/
class BPlusTreeLeaf : public BPlusTreeNode {
public:
    using BPlusTreeNode::BPlusTreeNode;

    bool is_leaf() const override
    {
        return true;
    }

    bool is_compact() const override
    {
        return true;
    }

    ref_type bptree_insert(size_t n, State& state, InsertFunc) override;
    void bptree_access(size_t n, AccessFunc) override;
    size_t bptree_erase(size_t n, EraseFunc) override;
    bool bptree_traverse(TraverseFunc) override;
};

/*****************************************************************************/
/* BPlusTreeBase                                                             */
/* Base class for the actual tree classes.                                   */
/*****************************************************************************/
class BPlusTreeBase {
public:
    BPlusTreeBase(Allocator& alloc)
        : m_alloc(alloc)
    {
        invalidate_leaf_cache();
    }
    virtual ~BPlusTreeBase();


    Allocator& get_alloc() const
    {
        return m_alloc;
    }

    bool is_attached() const
    {
        return bool(m_root);
    }

    bool get_context_flag() const noexcept
    {
        return m_root->get_context_flag();
    }

    void set_context_flag(bool cf) noexcept
    {
        m_root->set_context_flag(cf);
    }

    size_t size() const
    {
        return m_size;
    }

    bool is_empty() const
    {
        return m_size == 0;
    }

    ref_type get_ref() const
    {
        REALM_ASSERT(is_attached());
        return m_root->get_ref();
    }

    void init_from_ref(ref_type ref)
    {
        auto new_root = create_root_from_ref(ref);
        new_root->bp_set_parent(m_parent, m_ndx_in_parent);

        m_root = std::move(new_root);

        invalidate_leaf_cache();
        m_size = m_root->get_tree_size();
    }

    bool init_from_parent()
    {
        ref_type ref = m_parent->get_child_ref(m_ndx_in_parent);
        if (!ref) {
            return false;
        }
        auto new_root = create_root_from_ref(ref);
        new_root->bp_set_parent(m_parent, m_ndx_in_parent);
        m_root = std::move(new_root);
        invalidate_leaf_cache();
        m_size = m_root->get_tree_size();
        return true;
    }

    void set_parent(ArrayParent* parent, size_t ndx_in_parent)
    {
        m_parent = parent;
        m_ndx_in_parent = ndx_in_parent;
        if (is_attached())
            m_root->bp_set_parent(parent, ndx_in_parent);
    }

    virtual void erase(size_t) = 0;
    virtual void clear() = 0;

    void create();
    void destroy();
    void verify() const
    {
        m_root->verify();
    }

protected:
    template <class U>
    struct LeafTypeTrait {
        using type = typename ColumnTypeTraits<U>::cluster_leaf_type;
    };

    friend class BPlusTreeInner;
    friend class BPlusTreeLeaf;

    std::unique_ptr<BPlusTreeNode> m_root;
    Allocator& m_alloc;
    ArrayParent* m_parent = nullptr;
    size_t m_ndx_in_parent = 0;
    size_t m_size = 0;
    size_t m_cached_leaf_begin;
    size_t m_cached_leaf_end;

    void set_leaf_bounds(size_t b, size_t e)
    {
        m_cached_leaf_begin = b;
        m_cached_leaf_end = e;
    }

    void invalidate_leaf_cache()
    {
        m_cached_leaf_begin = size_t(-1);
        m_cached_leaf_end = size_t(-1);
    }

    void adjust_leaf_bounds(int incr)
    {
        m_cached_leaf_end += incr;
    }

    void bptree_insert(size_t n, BPlusTreeNode::InsertFunc func);
    void bptree_erase(size_t n, BPlusTreeNode::EraseFunc func);

    // Create an un-attached leaf node
    virtual std::unique_ptr<BPlusTreeLeaf> create_leaf_node() = 0;
    // Create a leaf node and initialize it with 'ref'
    virtual std::unique_ptr<BPlusTreeLeaf> init_leaf_node(ref_type ref) = 0;

    // Initialize the leaf cache with 'mem'
    virtual BPlusTreeLeaf* cache_leaf(MemRef mem) = 0;
    virtual void replace_root(std::unique_ptr<BPlusTreeNode> new_root);
    std::unique_ptr<BPlusTreeNode> create_root_from_ref(ref_type ref);
};

template <>
struct BPlusTreeBase::LeafTypeTrait<ObjKey> {
    using type = ArrayKeyNonNullable;
};

/*****************************************************************************/
/* BPlusTree                                                                 */
/* Actual implementation of the BPlusTree to hold elements of type T.        */
/*****************************************************************************/
template <class T>
class BPlusTree : public BPlusTreeBase {
public:
    using LeafArray = typename LeafTypeTrait<T>::type;
    using value_type = T;

    /**
     * Actual class for the leaves. Maps the abstract interface defined
     * in BPlusTreeNode onto the specific array class
     **/
    class LeafNode : public BPlusTreeLeaf, public LeafArray {
    public:
        LeafNode(BPlusTreeBase* tree)
            : BPlusTreeLeaf(tree)
            , LeafArray(tree->get_alloc())
        {
        }

        void init_from_ref(ref_type ref) noexcept override
        {
            LeafArray::init_from_ref(ref);
        }

        ref_type get_ref() const override
        {
            return LeafArray::get_ref();
        }

        void bp_set_parent(realm::ArrayParent* p, size_t n) override
        {
            LeafArray::set_parent(p, n);
        }

        void update_parent() override
        {
            LeafArray::update_parent();
        }

        size_t get_node_size() const override
        {
            return LeafArray::size();
        }

        size_t get_tree_size() const override
        {
            return LeafArray::size();
        }

        void move(BPlusTreeNode* new_node, size_t ndx, int64_t) override
        {
            LeafNode* dst(static_cast<LeafNode*>(new_node));
            LeafArray::move(*dst, ndx);
        }
        void verify() const override
        {
            LeafArray::verify();
        }
    };

    BPlusTree(Allocator& alloc)
        : BPlusTreeBase(alloc)
        , m_leaf_cache(this)
    {
    }

    /************ Tree manipulation functions ************/

    static T default_value(bool nullable = false)
    {
        return LeafArray::default_value(nullable);
    }

    void add(T value)
    {
        insert(npos, value);
    }

    void insert(size_t n, T value)
    {
        auto func = [value](BPlusTreeNode* node, size_t ndx) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            leaf->LeafArray::insert(ndx, value);
            return leaf->size();
        };

        bptree_insert(n, func);
        m_size++;
    }

    inline T get(size_t n) const
    {
        // Fast path
        if (m_cached_leaf_begin <= n && n < m_cached_leaf_end) {
            return m_leaf_cache.get(n - m_cached_leaf_begin);
        }
        else {
            // Slow path
            return get_uncached(n);
        }
    }

    REALM_NOINLINE T get_uncached(size_t n) const
    {
        T value;

        auto func = [&value](BPlusTreeNode* node, size_t ndx) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            value = leaf->get(ndx);
        };

        m_root->bptree_access(n, func);

        return value;
    }

    std::vector<T> get_all() const
    {
        std::vector<T> all_values;
        all_values.reserve(m_size);

        auto func = [&all_values](BPlusTreeNode* node, size_t) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            size_t sz = leaf->size();
            for (size_t i = 0; i < sz; i++) {
                all_values.push_back(leaf->get(i));
            }
            return IteratorControl::AdvanceToNext;
        };

        m_root->bptree_traverse(func);

        return all_values;
    }

    void set(size_t n, T value)
    {
        auto func = [value](BPlusTreeNode* node, size_t ndx) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            leaf->set(ndx, value);
        };

        m_root->bptree_access(n, func);
    }

    void swap(size_t ndx1, size_t ndx2)
    {
        if constexpr (std::is_same_v<T, StringData> || std::is_same_v<T, BinaryData>) {
            struct SwapBuffer {
                std::string val;
                bool n;
                SwapBuffer(T v)
                    : val(v.data(), v.size())
                    , n(v.is_null())
                {
                }
                T get()
                {
                    return n ? T() : T(val);
                }
            };
            SwapBuffer tmp1{get(ndx1)};
            SwapBuffer tmp2{get(ndx2)};
            set(ndx1, tmp2.get());
            set(ndx2, tmp1.get());
        }
        else if constexpr (std::is_same_v<T, Mixed>) {
            std::string buf1;
            std::string buf2;
            Mixed tmp1 = get(ndx1);
            Mixed tmp2 = get(ndx2);
            if (tmp1.is_type(type_String, type_Binary)) {
                tmp1.use_buffer(buf1);
            }
            if (tmp2.is_type(type_String, type_Binary)) {
                tmp2.use_buffer(buf2);
            }
            set(ndx1, tmp2);
            set(ndx2, tmp1);
        }
        else {
            T tmp = get(ndx1);
            set(ndx1, get(ndx2));
            set(ndx2, tmp);
        }
    }

    void erase(size_t n) override
    {
        auto func = [](BPlusTreeNode* node, size_t ndx) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            leaf->LeafArray::erase(ndx);
            return leaf->size();
        };

        bptree_erase(n, func);
        m_size--;
    }

    void clear() override
    {
        if (m_root->is_leaf()) {
            LeafNode* leaf = static_cast<LeafNode*>(m_root.get());
            leaf->clear();
        }
        else {
            destroy();
            create();
            if (m_parent) {
                m_parent->update_child_ref(m_ndx_in_parent, get_ref());
            }
        }
        m_size = 0;
    }

    void traverse(BPlusTreeNode::TraverseFunc func) const
    {
        if (m_root) {
            m_root->bptree_traverse(func);
        }
    }

    size_t find_first(T value) const noexcept
    {
        size_t result = realm::npos;

        auto func = [&result, value](BPlusTreeNode* node, size_t offset) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            size_t sz = leaf->size();
            auto i = leaf->find_first(value, 0, sz);
            if (i < sz) {
                result = i + offset;
                return IteratorControl::Stop;
            }
            return IteratorControl::AdvanceToNext;
        };

        m_root->bptree_traverse(func);

        return result;
    }

    template <typename Func>
    void find_all(T value, Func&& callback) const noexcept
    {
        auto func = [&callback, value](BPlusTreeNode* node, size_t offset) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            size_t i = -1, sz = leaf->size();
            while ((i = leaf->find_first(value, i + 1, sz)) < sz) {
                callback(i + offset);
            }
            return IteratorControl::AdvanceToNext;
        };

        m_root->bptree_traverse(func);
    }

    template <typename Func>
    void for_all(Func&& callback) const
    {
        using Ret = std::invoke_result_t<Func, T>;
        m_root->bptree_traverse([&callback](BPlusTreeNode* node, size_t) {
            LeafNode* leaf = static_cast<LeafNode*>(node);
            size_t sz = leaf->size();
            for (size_t i = 0; i < sz; i++) {
                if constexpr (std::is_same_v<Ret, void>) {
                    callback(leaf->get(i));
                }
                else {
                    if (!callback(leaf->get(i)))
                        return IteratorControl::Stop;
                }
            }
            return IteratorControl::AdvanceToNext;
        });
    }

protected:
    LeafNode m_leaf_cache;

    /******** Implementation of abstract interface *******/

    std::unique_ptr<BPlusTreeLeaf> create_leaf_node() override
    {
        std::unique_ptr<BPlusTreeLeaf> leaf = std::make_unique<LeafNode>(this);
        static_cast<LeafNode*>(leaf.get())->create();
        return leaf;
    }
    std::unique_ptr<BPlusTreeLeaf> init_leaf_node(ref_type ref) override
    {
        std::unique_ptr<BPlusTreeLeaf> leaf = std::make_unique<LeafNode>(this);
        leaf->init_from_ref(ref);
        return leaf;
    }
    BPlusTreeLeaf* cache_leaf(MemRef mem) override
    {
        m_leaf_cache.init_from_mem(mem);
        return &m_leaf_cache;
    }
    void replace_root(std::unique_ptr<BPlusTreeNode> new_root) override
    {
        // Only copy context flag over in a linklist.
        // The flag is in use in other list types
        if constexpr (std::is_same_v<T, ObjKey>) {
            auto cf = m_root ? m_root->get_context_flag() : false;
            BPlusTreeBase::replace_root(std::move(new_root));
            m_root->set_context_flag(cf);
        }
        else {
            BPlusTreeBase::replace_root(std::move(new_root));
        }
    }

    template <class R>
    friend R bptree_sum(const BPlusTree<T>& tree);
};

template <class T>
using SumAggType = typename aggregate_operations::Sum<typename util::RemoveOptional<T>::type>;

template <class T>
typename SumAggType<T>::ResultType bptree_sum(const BPlusTree<T>& tree, size_t* return_cnt = nullptr)
{
    SumAggType<T> agg;

    auto func = [&agg](BPlusTreeNode* node, size_t) {
        auto leaf = static_cast<typename BPlusTree<T>::LeafNode*>(node);
        size_t sz = leaf->size();
        for (size_t i = 0; i < sz; i++) {
            auto val = leaf->get(i);
            agg.accumulate(val);
        }
        return IteratorControl::AdvanceToNext;
    };

    tree.traverse(func);

    if (return_cnt)
        *return_cnt = agg.items_counted();

    return agg.result();
}

template <class AggType, class T>
util::Optional<typename util::RemoveOptional<T>::type> bptree_min_max(const BPlusTree<T>& tree,
                                                                      size_t* return_ndx = nullptr)
{
    AggType agg;
    if (tree.size() == 0) {
        if (return_ndx)
            *return_ndx = not_found;
        return util::none;
    }

    auto func = [&agg, return_ndx](BPlusTreeNode* node, size_t offset) {
        auto leaf = static_cast<typename BPlusTree<T>::LeafNode*>(node);
        size_t sz = leaf->size();
        for (size_t i = 0; i < sz; i++) {
            auto val_or_null = leaf->get(i);
            bool found_new_min = agg.accumulate(val_or_null);
            if (found_new_min && return_ndx) {
                *return_ndx = i + offset;
            }
        }
        return IteratorControl::AdvanceToNext;
    };

    tree.traverse(func);

    return agg.is_null() ? util::none : std::optional{agg.result()};
}

template <class T>
using MinAggType = typename aggregate_operations::Minimum<typename util::RemoveOptional<T>::type>;

template <class T>
util::Optional<typename util::RemoveOptional<T>::type> bptree_minimum(const BPlusTree<T>& tree,
                                                                      size_t* return_ndx = nullptr)
{
    return bptree_min_max<MinAggType<T>, T>(tree, return_ndx);
}

template <class T>
using MaxAggType = typename aggregate_operations::Maximum<typename util::RemoveOptional<T>::type>;

template <class T>
util::Optional<typename util::RemoveOptional<T>::type> bptree_maximum(const BPlusTree<T>& tree,
                                                                      size_t* return_ndx = nullptr)
{
    return bptree_min_max<MaxAggType<T>, T>(tree, return_ndx);
}

template <class T>
ColumnAverageType<T> bptree_average(const BPlusTree<T>& tree, size_t* return_cnt = nullptr)
{
    size_t cnt;
    auto sum = bptree_sum(tree, &cnt);
    ColumnAverageType<T> avg{};
    if (cnt != 0)
        avg = ColumnAverageType<T>(sum) / cnt;
    if (return_cnt)
        *return_cnt = cnt;
    return avg;
}
} // namespace realm

#endif /* REALM_BPLUSTREE_HPP */
