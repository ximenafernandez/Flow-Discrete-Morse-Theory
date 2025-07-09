from Flow_Category.Flow2 import *

### Homotopy posets

import random

def remove_point(X, x):
	elms=[y for y in X.list() if not y == x]
	return X.subposet(elms)

def is_beat_point(X, x):
    return len(X.upper_covers(x)) == 1 or len(X.lower_covers(x)) == 1

def beat_points(X):
    return [x for x in X.list() if is_beat_point(X,x)]

def core(X): 
    for x in beat_points(X):
        X = remove_point(X, x)
        return core(X)
    return X

def is_contractible(X):
    if X.has_top() or X.has_bottom():
        return True
    return core(X).cardinality() == 1

def F_hat(X, x):
	elms=[y for y in X.list() if X.is_greater_than(y, x)]
	return X.subposet(elms)

def U_hat(X, x):
	elms=[y for y in X.list() if X.is_greater_than(x, y)]
	return X.subposet(elms)

def is_weak_point(X, x):
	return (is_contractible(U_hat(X, x)) or is_contractible(F_hat(X, x)))

def weak_points(X):
	return [x for x in X.list() if is_weak_point(X, x)]

def weak_core(X):
	for x in weak_points(X):
		X = remove_point(X, x)
		return weak_core(X)
	return X

def is_collapsible(X):
    if is_contractible(X):
        return True
    return len(weak_core(X))==1

from sage.homology.homology_group import HomologyGroup

def is_homotopically_trivial(X):
    if is_collapsible(X): return True
    K = X.order_complex()
    H = K.homology()
    for i in H.keys():
        if H[i]!=HomologyGroup(0, ZZ):
            return False
    Pi1 = K.fundamental_group()
    # Fallbacks for when group methods are not available
    try:
        return Pi1.is_trivial()
    except Exception:
        pass
    try:
        return len(Pi1.gens()) == 0
    except Exception:
        pass
    try:
        # This should catch the "Group(<identity> of ...)" case
        return str(Pi1).strip().startswith("Group( <identity>")
    except Exception:
        pass
    # As a last fallback, we assume it's not trivial
    return False


#Regular acyclic matchings

def is_regular_flow_category(P, elms_X, e):
    """
    P is a regular flow category
    e a proposed new element in a matching
    """
    x = e[1]
    y = e[0]
    Q = {}
    for w in elms_X:
            if w != x and len(P[(w, y)]) != 0:  
                for z in elms_X:
                    if z != y and len(P[(x, z)]) != 0: 
                        Q[(w,z)] = adjoin2(P[(w, z)], (y, x), P[(w, y)], P[(x, z)], P[(w, x)], P[(y, z)])
                        if not is_homotopically_trivial(Q[(w,z)]):
                            return (False, [])
    for (a,b) in Q.keys():
        P[(a,b)] = Q[(a,b)]
    return (True, P)




def regular_acyclic_matching(X):
    
    '''
    Greedy algorithm that ouputs a greedy (maximal) regular acyclic matching.
    INPUT: X the face poset of regular CW.
    '''
    M = []
    P = flow_category2(X, M)
    
    edges = X.cover_relations()
    in_match = {}
    for v in X.list():
        in_match[v] = False
    seed()
    shuffle(edges)
    
    for e in edges:
        if(in_match[e[0]] or in_match[e[1]]):
            continue
        D = DiGraph(edges)
        D.reverse_edge(e)
        if D.is_directed_acyclic():
            bool, PP = is_regular_flow_category(P, X.list(), e)
            if bool:
                P = deepcopy(PP)
                edges.remove(e)
                edges.append([e[1], e[0]])
                M.append(e)
                in_match[e[0]] = True
                in_match[e[1]] = True
    return M

######################################

def update_flow_category(P, elms_X, e):
    """
    P is a regular flow category
    e a proposed new element in a matching
    """
    x = e[1]
    y = e[0]
    Q = {}
    for w in elms_X:
            if w != x and len(P[(w, y)]) != 0:  
                for z in elms_X:
                    if z != y and len(P[(x, z)]) != 0: 
                        Q[(w,z)] = adjoin2(P[(w, z)], (y, x), P[(w, y)], P[(x, z)], P[(w, x)], P[(y, z)])
    for (a,b) in Q.keys():
        P[(a,b)] = Q[(a,b)]
    return P

def update_matching(M, e, in_match, edges):
    edges.remove(e)
    edges.append([e[1], e[0]])
    M.append(e)
    in_match[e[0]] = True
    in_match[e[1]] = True

import random
def regular_acyclic_matching2(X, p, seed_value = 123):
        
    '''
    Greedy algorithm that ouputs a random (maximal) regular acyclic matching.
    INPUT: X the face poset of regular CW.
    p: Probability of checking it is regular during the process
    '''
    M = []
    P = flow_category2(X, M)

    edges = X.cover_relations()
    in_match = {}
    for v in X.list():
        in_match[v] = False
    random.seed(float(seed_value))
    shuffle(edges)
    
    for e in edges:
        if(in_match[e[0]] or in_match[e[1]]):
            continue
        D = DiGraph(edges)
        D.reverse_edge(e)
        
        if D.is_directed_acyclic():
            PP = update_flow_category(P, X.list(), e)
            rnd = random.uniform(0, 1)
            print(rnd)
            if rnd<p:
                if is_regular_flow(PP):
                    P = deepcopy(PP)
                    update_matching(M, e, in_match, edges)
                    print(M)
                    print(is_regular_matching(X, M))
            else:
                update_matching(M, e, in_match, edges)
                print(M)
                print(is_regular_matching(X, M))
             
    return is_regular_matching(X, M), M

def is_regular_flow(P):
    for pair in P.keys():
        if not is_homotopically_trivial(P[pair]): 
            return False
    return True

#######################################

def random_acyclic_matching(X, seed_value=123):
        
    '''
    Greedy algorithm that ouputs a random (maximal) acyclic matching.
    INPUT: X the face poset of regular CW.
    '''
    M = []    
    edges = X.cover_relations()
    in_match = {}
    for v in X.list():
        in_match[v] = False
    seed(seed_value)
    shuffle(edges)
    
    for e in edges:
        if(in_match[e[0]] or in_match[e[1]]):
            continue
        D = DiGraph(edges)
        D.reverse_edge(e)
        if D.is_directed_acyclic():
            edges.remove(e)
            edges.append([e[1], e[0]])
            M.append(e)
            in_match[e[0]] = True
            in_match[e[1]] = True
    return M

def is_regular_matching(X, M):
    F = flow_category2(X, M)
    for pair in F.keys():
        if not is_homotopically_trivial(F[pair]):
            print(pair)
            return False
    return True


######################################


def flow_regular_matching_full_check(X, max_dim=None):
    '''
    Construct a flow-regular acyclic matching (satisfying condition (*)) on X.

    Parameters:
        X: A regular CW complex or simplicial complex (as a poset)
        max_dim: Optional dimension cutoff for matchings

    Returns:
        M: List of matched pairs (a, b) such that the final flow category is regular
    '''
    from sage.all import DiGraph
    import random

    elms = X.list()
    M = []
    in_match = {v: False for v in elms}
    edges = [(a, b) for (a, b) in X.cover_relations()]
    D = DiGraph(edges)
    random.shuffle(edges)

    P = flow_category2(X, M)

    def is_flow_category_regular(P, elms):
        for x in elms:
            for y in elms:
                if (x, y) in P and not is_homotopically_trivial(P[(x, y)]):
                    return False
        return True

    for e in edges:
        a, b = e
        if in_match[a] or in_match[b]:
            continue
        if max_dim is not None:
            if max(X.dimension(a), X.dimension(b)) > max_dim:
                continue
        D_rev = D.copy()
        D_rev.delete_edge(a, b)
        D_rev.add_edge(b, a)
        if not D_rev.is_directed_acyclic():
            continue

        try:
            PP = update_flow_category(P, elms, e)
        except:
            continue

        if is_flow_category_regular(PP, elms):
            M.append(e)
            P = PP
            D = D_rev
            in_match[a] = True
            in_match[b] = True

    return M
