def critical_points(X, M):
    C = X.list()
    for x in M:
        C.remove(x[0])
        C.remove(x[1])
    return C

def reversed_edges(X, M):
    cover_relations = X.cover_relations()
    for x in M:
        cover_relations.remove([x[0], x[1]])  # Remove original directed edges
        cover_relations.append([x[1], x[0]])  # Add reversed edges
    return cover_relations


def is_acyclic(X, M):
    edges = X.cover_relations()
    D = DiGraph(edges)
    for e in M:
        D.reverse_edge(e)
    return D.is_directed_acyclic()
    

def critical_poset(X, M):
    C = critical_points(X, M)
    R = reversed_edges(X, M)
    Crit = Poset([X.list(), R], cover_relations=False).subposet(C)
    return Crit

def localization_poset(X, M):
    """
    Collapse a poset X by identifying elements in the acyclic matching.
    
    Each pair (x, y) in the matching satisfies x < y.
    We identify x and y into a single element and return the resulting quotient poset.

    Parameters:
    - X: A poset 
    - M: A list of pairs (x, y) with x < y representing the acyclic matching.

    Returns:
    - Q: The quotient poset where each pair in the matching has been identified.
    """
    
    # Build equivalence classes via disjoint set structure
    ds = DisjointSet(X.list())
    for x, y in M:
        ds.union(x, y)
    
    # Map each element to its equivalence class representative
    rep = {x: ds.find(x) for x in X}
    
    # List of unique class representatives
    new_elements = set(rep.values())
    
    # Define new covering relations between representatives
    new_relations = set()
    for x in X:
        for y in X.upper_covers(x):
            rx = rep[x]
            ry = rep[y]
            if rx != ry:
                new_relations.add((rx, ry))
    
    # Construct and return the quotient poset
    Q = Poset((new_elements, list(new_relations)))
    
    return Q