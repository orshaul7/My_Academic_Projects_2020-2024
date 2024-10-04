# Procedure to calculate the AT values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]

proc calcAT {adjMat wMat nodes} {
    # Sort nodes in topological order
    set sortedNodes [topologicalSort $nodes $adjMat]
    
    #calculating the Arrival time of each node
    foreach node $sortedNodes {
        set nodeId [lindex $node 0]
        set maxAT 0
        foreach fromNode $nodes {
            set fromNodeId [lindex $fromNode 0]
            if {[lindex $adjMat $fromNodeId $nodeId] == 1} {
                set at [lindex $nodes $fromNodeId 1]
                set weight [lindex $wMat $fromNodeId $nodeId]
                set maxAT [expr {max($maxAT, $at + $weight)}]
            }
        }
        set nodes [lreplace $nodes $nodeId $nodeId [list $nodeId $maxAT 0 0]]
    }
    
    return $nodes
}


# Procedure to calculate the RAT values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]
proc calcRAT {adjMat wMat nodes T} {
       
    # Sort nodes in reverse topological order

    set sortedNodes [topologicalSort $nodes $adjMat]
    set reverseSortedNodes [lreverse $sortedNodes]
    
    # Calculate RAT for each node
    foreach node $reverseSortedNodes {
        set nodeId [lindex $node 0]
        set minRAT $T
        foreach toNode $nodes {
            set toNodeId [lindex $toNode 0]
            if {[lindex $adjMat $nodeId $toNodeId] == 1} {
                set rat [lindex $nodes $toNodeId 2]
                set weight [lindex $wMat $nodeId $toNodeId]
                set minRAT [expr {min($minRAT, $rat - $weight)}]
            }
        }
        set nodes [lreplace $nodes $nodeId $nodeId [list $nodeId [lindex $nodes $nodeId 1] $minRAT 0]]
    }
    
    return $nodes
}


# Procedure to calculate the SLACK values for each node in a graph
# adjMat - adjacency matrix of the graph
# wMat - weight matrix of the graph
# nodes - list of nodes in the graph, each node represented as a list [id AT RAT SLACK]
proc calcSlack {adjMat wMat nodes T} {
    # Calculate the AT values
    set nodes [calcAT $adjMat $wMat $nodes]
    
    # Calculate the RAT values
    set nodes [calcRAT $adjMat $wMat $nodes $T]
    
    # Calculate the slack for each node and report if the slack is negative
    foreach node $nodes {
        set nodeId [lindex $node 0]
        set at [lindex $node 1]
        set rat [lindex $node 2]
        set slack [expr {$rat - $at}]
        set nodes [lreplace $nodes $nodeId $nodeId [list $nodeId $at $rat $slack]]
        if {$slack < 0} {
            puts "Node $nodeId has negative slack: $slack"
        }
    }
    
    return $nodes
}

# Define a function to initialize a queue
proc init_queue {qvar} {
  upvar 1 $qvar Q
  set Q [list]
}

# Define a function to add an element to a queue
proc enqueue {qvar elem} {
  upvar 1 $qvar Q
  lappend Q $elem
}

# Define a function to remove an element from a queue
proc dequeue {qvar} {
  upvar 1 $qvar Q
  set head [lindex $Q 0]
  set Q [lrange $Q 1 end]
  return $head
}

# Define a function to check if a queue is empty
proc is_empty {qvar} {
  upvar 1 $qvar Q
  return [expr {[llength $Q] == 0}]
}

proc topologicalSort {nodes adjMat} {

  # Create an empty list to hold the sorted nodes
  set sortedList {}
  # Compute the indegree of each node
  array set indegrees {}
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    set indegrees([lindex $nodes $i 0]) 0
  }
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    set currentIndex [lindex [lindex $nodes $i] 0]
    for {set j 0} {$j < [llength $adjMat]} {incr j} {
        if {[lindex $adjMat $j $currentIndex] == 1} {
          incr indegrees([lindex $nodes $i 0])
      }
    }
  }

  # Create a queue and add all nodes with indegree 0
  init_queue Q
  for {set i 0} {$i < [llength $nodes]} {incr i} {
    if {$indegrees([lindex $nodes $i 0]) == 0} {
      enqueue Q [lindex $nodes $i]
    }
  }

  # Visit all nodes in the queue
  while {! [is_empty Q]} {
    set currentNode [dequeue Q]
    set currentIndex [lindex $currentNode 0]
    lappend sortedList $currentNode
    for {set i 0} {$i < [llength $adjMat]} {incr i} {
      if {[lindex $adjMat $currentIndex $i] == 1} {
        incr indegrees([lindex $nodes $i 0]) -1
        if {$indegrees([lindex $nodes $i 0]) == 0} {
          enqueue Q [lindex $nodes $i]
        }
      }
    }
  }
   #Check if a cycle exists
  if {[llength $sortedList] != [llength $nodes]} {
    return "Error: Graph contains a cycle"
  }
  return $sortedList
}



# Example input data as matrices for INPUT_1
set adjacencyMatrix { {0 1 1 1 0 0 0 0 0 0 0} {0 0 0 0 1 1 0 0 0 0 0} {0 0 0 0 0 1 0 0 0 0 0} {0 0 0 0 0 1 1 0 0 0 0} {0 0 0 0 0 0 0 1 0 0 0} {0 0 0 0 0 0 0 1 1 1 0} {0 0 0 0 0 0 0 0 1 1 0} {0 0 0 0 0 0 0 0 0 0 1} {0 0 0 0 0 0 0 0 0 0 1} {0 0 0 0 0 0 0 0 0 0 1} {0 0 0 0 0 0 0 0 0 0 0} }
set weightsMatrix { {0 0 0 0 0 0 0 0 0 0 0} {0 0 0 0 4 6 0 0 0 0 0} {0 0 0 0 0 4 0 0 0 0 0} {0 0 0 0 0 1 2 0 0 0 0} {0 0 0 0 0 0 0 2 0 0 0} {0 0 0 0 0 0 0 1 6 9 0} {0 0 0 0 0 0 0 0 5 8 0} {0 0 0 0 0 0 0 0 0 0 0} {0 0 0 0 0 0 0 0 0 0 0} {0 0 0 0 0 0 0 0 0 0 0} {0 0 0 0 0 0 0 0 0 0 0} }
set nodesList { {0 0 0 0} {1 0 0 0} {2 0 0 0} {3 0 0 0} {4 0 0 0} {5 0 0 0} {6 0 0 0} {7 0 0 0} {8 0 0 0} {9 0 0 0} {10 0 0 0} }

# Running the main function
set result [calcSlack $adjacencyMatrix $weightsMatrix $nodesList 12]
puts $result




# Example input data as matrices for INPUT_2
set adjacencyMatrix { {0 1 0 0 0 0 0 0} {0 0 1 1 0 0 0 0} {0 0 0 0 1 0 0 0} {0 0 0 0 1 1 0 0} {0 0 0 0 0 0 1 1} {0 0 0 0 0 0 0 1} {0 0 0 0 0 0 0 1} {0 0 0 0 0 0 0 0}}
set weightsMatrix {  {0 0 0 0 0 0 0 0} {0 0 1 3 0 0 0 0} {0 0 0 0 4 0 0 0} {0 0 0 0 1 2 0 0} {0 0 0 0 0 0 5 0} {0 0 0 0 0 0 0 0} {0 0 0 0 0 0 0 0} {0 0 0 0 0 0 0 0}}
set nodesList { {0 0 0 0} {1 0 0 0} {2 0 0 0} {3 0 0 0} {4 0 0 0} {5 0 0 0} {6 0 0 0} {7 0 0 0}}

# Running the main function
set result [calcSlack $adjacencyMatrix $weightsMatrix $nodesList 9]
puts $result

 
