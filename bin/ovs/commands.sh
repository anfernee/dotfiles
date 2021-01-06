#!/bin/bash

# List all interfaces with specific columns
ovs-vsctl -- --columns=name,ofport list Interface

# List all interfaces with all information
ovs-vsctl list Interface


