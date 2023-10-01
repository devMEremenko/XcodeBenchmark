/*************************************************************************
 *
 * Copyright 2022 Realm Inc.
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

#ifndef REALM_GEOSPATIAL_HPP
#define REALM_GEOSPATIAL_HPP

#include "external/mpark/variant.hpp"

#include <realm/keys.hpp>
#include <realm/string_data.hpp>

#include <climits>
#include <cmath>
#include <optional>
#include <string_view>
#include <vector>

class S2Region;

namespace realm {

class Obj;
class TableRef;
class Geospatial;

struct GeoPoint {
    double longitude = get_nan();
    double latitude = get_nan();
    double altitude = get_nan();

    bool operator==(const GeoPoint& other) const
    {
        return (longitude == other.longitude || (std::isnan(longitude) && std::isnan(other.longitude))) &&
               (latitude == other.latitude || (std::isnan(latitude) && std::isnan(other.latitude))) &&
               ((!has_altitude() && !other.has_altitude()) || altitude == other.altitude);
    }
    bool operator!=(const GeoPoint& other) const
    {
        return !(*this == other);
    }

    bool is_valid() const
    {
        return !std::isnan(longitude) && !std::isnan(latitude);
    }

    bool has_altitude() const
    {
        return !std::isnan(altitude);
    }

    std::optional<double> get_altitude() const noexcept
    {
        return std::isnan(altitude) ? std::optional<double>{} : altitude;
    }

    void set_altitude(std::optional<double> val) noexcept
    {
        altitude = val.value_or(get_nan());
    }

    constexpr static double get_nan()
    {
        return std::numeric_limits<double>::quiet_NaN();
    }
};

// A simple spherical polygon. It consists of a single
// chain of vertices where the first vertex is implicitly connected to the
// last. Chain of vertices is defined to have a CCW orientation, i.e. the interior
// of the polygon is on the left side of the edges.
// For Polygons with multiple rings:
//   - The first described ring must be the exterior ring.
//   - The exterior ring cannot self-intersect.
//   - Any interior ring must be entirely contained by the outer ring.
//   - Interior rings cannot intersect or overlap each other. Interior rings cannot share an edge.
struct GeoPolygon {
    bool operator==(const GeoPolygon& other) const
    {
        return points == other.points;
    }
    std::vector<std::vector<GeoPoint>> points;
};

// This is a shortcut for creating a polygon with a "rectangular" shape. It is just
// syntatic sugar for making a viewport like region such as a device screen. The
// ordering of points does not matter. Results are undefined if the intended region
// wraps a pole.
struct GeoBox {
    GeoPoint lo;
    GeoPoint hi;
    bool operator==(const GeoBox& other) const
    {
        return lo == other.lo && hi == other.hi;
    }
    GeoPolygon to_polygon() const;
    static std::optional<GeoBox> from_polygon(const GeoPolygon&);
};

struct GeoCircle {
    double radius_radians = 0.0;
    GeoPoint center;

    bool operator==(const GeoCircle& other) const
    {
        return radius_radians == other.radius_radians && center == other.center;
    }

    // Equatorial radius of earth.
    // src/mongo/db/geo/geoconstants.h
    constexpr static double c_radius_meters = 6378100.0;

    static GeoCircle from_kms(double km, GeoPoint&& p)
    {
        return GeoCircle{km * 1000 / c_radius_meters, p};
    }
};

class GeoRegion {
public:
    GeoRegion(const Geospatial& geo);
    ~GeoRegion();

    bool contains(const std::optional<GeoPoint>& point) const noexcept;
    Status get_conversion_status() const noexcept;

private:
    std::unique_ptr<S2Region> m_region;
    Status m_status;
};

class Geospatial {
public:
    enum class Type : uint8_t { Invalid, Point, Box, Polygon, Circle };

    Geospatial()
        : m_value(mpark::monostate{})
    {
    }
    Geospatial(GeoPoint point)
        : m_value(point)
    {
    }
    Geospatial(GeoBox box)
        : m_value(box)
    {
    }
    Geospatial(GeoPolygon polygon)
        : m_value(polygon)
    {
    }
    Geospatial(GeoCircle circle)
        : m_value(circle)
    {
    }

    Geospatial(const Geospatial& other)
        : m_value(other.m_value)
    {
    }
    Geospatial& operator=(const Geospatial& other)
    {
        if (this != &other) {
            m_value = other.m_value;
        }
        return *this;
    }

    Geospatial(Geospatial&& other) = default;
    Geospatial& operator=(Geospatial&&) = default;

    static std::optional<GeoPoint> point_from_obj(const Obj& obj, ColKey type_col = {}, ColKey coords_col = {});
    static Geospatial from_link(const Obj& obj);
    static bool is_geospatial(const TableRef table, ColKey link_col);
    void assign_to(Obj& link) const;

    std::string get_type_string() const noexcept;
    Type get_type() const noexcept;

    template <class T>
    const T& get() const noexcept;

    Status is_valid() const noexcept;

    bool contains(const GeoPoint& point) const noexcept;

    std::string to_string() const;

    bool operator==(const Geospatial& other) const
    {
        return m_value == other.m_value;
    }
    bool operator!=(const Geospatial& other) const
    {
        return !(*this == other);
    }
    bool operator>(const Geospatial&) const = delete;
    bool operator<(const Geospatial& other) const = delete;
    bool operator>=(const Geospatial& other) const = delete;
    bool operator<=(const Geospatial& other) const = delete;

    constexpr static std::string_view c_geo_point_type_col_name = "type";
    constexpr static std::string_view c_geo_point_coords_col_name = "coordinates";

private:
    // Must be in the same order as the Type enum
    mpark::variant<mpark::monostate, GeoPoint, GeoBox, GeoPolygon, GeoCircle> m_value;

    friend class GeoRegion;

    mutable std::unique_ptr<GeoRegion> m_region;
    GeoRegion& get_region() const;
};

template <>
inline const GeoCircle& Geospatial::get<GeoCircle>() const noexcept
{
    return mpark::get<GeoCircle>(m_value);
}

template <>
inline const GeoBox& Geospatial::get<GeoBox>() const noexcept
{
    return mpark::get<GeoBox>(m_value);
}

template <>
inline const GeoPoint& Geospatial::get<GeoPoint>() const noexcept
{
    return mpark::get<GeoPoint>(m_value);
}

template <>
inline const GeoPolygon& Geospatial::get<GeoPolygon>() const noexcept
{
    return mpark::get<GeoPolygon>(m_value);
}

std::ostream& operator<<(std::ostream& ostr, const Geospatial& geo);

} // namespace realm

#endif /* REALM_GEOSPATIAL_HPP */
