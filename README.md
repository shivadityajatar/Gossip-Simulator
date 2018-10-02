# Gossip Simulator
COP5615 - Distributed Operating Systems Principles Project 2

The goal of this project is to determine the convergence of Gossip and Push-Sum algorithms for different topologies through a simulator based on actors written in Elixir.

## Group Information
* **Ayush Mittal** - *UF ID: 3777 8171*
* **Shivaditya Jatar** - *UF ID: 6203 9241*

## Contents of this file

Flow of Program, Prerequisites, Instruction Section, What is working, Largest network dealt with for each type of topology and algorithm

## Flow of Program

* For Gossip and Push-Sum

There are 3 arguments to be passed:

* Input the number of nodes (will be rounded up for random 2d and 3d topologies)
* Input the topology
* Input the algorithm


#### For Bonus Part

There are 4 arguments to be passed:
* Input the number of nodes (will be rounded up for random 2d and 3d topologies)
* Input the topology
* Input the algorithm
* Input the number of nodes to be killed


## Prerequisites

#### Erlang OTP 21(10.0.1)
#### Elixir version 1.7.3

## Instruction section

#### To run the App

```elixir
(Before running, Goto project2 directory, where mix.exs is present)
$ cd project2
$ mix escript.build
$ escript project2 <No. of Nodes> <Topology> <Algorithm>
e.g. escript project2 40 {line | impline | torus | 3d | random2d | full } {gossip | push-sum}
SAMPLE O/P-> Waiting for convergence
.................................................................................................................................................................

Time utilized to converge : xxxx milliseconds
```
Starts the app, passing in No. of Nodes, Topology & Algorithm values. The console prints the time taken for the topology to converge for the algorithm and nodes given.

#### To run the App (Bonus Part)
```elixir
(Before running, Goto project2_bonus directory, where mix.exs is present)
$ cd project2_bonus
$ mix escript.build
$ escript project2_bonus <No. of Nodes> <Topology> <Algorithm> <No. of nodes to kill>
e.g. escript project2 200 {line | impline | torus | 3d | random2d | full } {gossip | push-sum} 20
SAMPLE O/P-> Waiting for convergence
.................................................................................................................................................................
No convergence for 2
No convergence for 1

Time utilized to converge : xxxx milliseconds
```
Starts the app, passing in No. of Nodes, Topology, Algorithm and No. of nodes to kill values. The console prints the time taken for the topology to converge for the algorithm and nodes given with failure model implemented.


## What is working

These 6 topologies are implemented:

1. Line
2. Full
3. Imperfect Line
4. 3D
5. Torus
6. Random 2D

* All of these topologies are working for both Gossip and Push-Sum algorithm.

Also implemented the failure model & tested the convergence for both algorithms & both topologies.

## Largest Network dealt with for each type of topology and algorithm

#### For Gossip Algorithm
* Full Topology : 84000 nodes
* 3D Topology : 75000 nodes
* Torus Topology : 65000 nodes
* Imperfect Line Topology : 40000 nodes
* Line Topology : 6000 nodes
* Random-2D Topology : 15000 nodes

#### For Push-Sum Algorithm
* Full Topology : 84000 nodes
* 3D Topology : 75000 nodes
* Torus Topology : 56000 nodes
* Imperfect Line Topology : 34000 nodes
* Line Topology : 5500 nodes
* Random-2D Topology : 14000 nodes
