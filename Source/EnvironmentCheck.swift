//
// EnvironmentCheck.swift
// XcodeBenchmark
//
// Created on 11/16/20.
//

#if targetEnvironment(simulator)

#error("Please select Any iOS Device as a target device")

#endif
