#!/usr/bin/env python3
import argparse
import itertools
import os

def kernelgen(nqubits, ids=None):
    # All combinations of qubits, excluding dupes, e.g. for nqubits = 2:
    # 0 0
    # 1 0
    # 0 1
    # 1 1
    combs = list(itertools.product([0, 1], repeat=nqubits))

    # Pretty-print the indexed PSI array values.
    strcombs = []
    for j in range(0, len(combs)):
        comb = tuple(reversed(combs[j]))
        strcomb = 'psi[I'.format(j)
        for i in range(0, nqubits):
            if comb[i] != 0:
                strcomb += " + d{}".format(i)
        strcomb += ']';
        strcombs.append(strcomb)

    def rhs(n, j, i):
        if i < n - 1:
            return f'add(mul(v[{i}], M({j}, {i})), ' + rhs(n, j, i + 1)
        else:
            return f'mul(v[{i}], M({j}, {i})' + ''.join(')' for k in range(0, n))

    # Pretty-print the right hand sides (recursively).
    strrhs = [] 
    for j in range(0, len(strcombs)):
        strrhs.append(rhs(len(strcombs), j, 0))

    dsorted = []
    if ids != None:
    	dsorted = sorted(ids, reverse = True)

    # Some string constants clash with the {} syntax of print(), so we
    # substitute them as constants.
    define = "#define"
    undef = "#undef"
    pragma = "#pragma"
    newline = "\n"

    kernel = \
"""
{include} <algorithm>
{include} <array>
{include} <complex>
{include} <cstdlib>

{define} add(a, b) (a + b)
{define} mul(a, b) (a * b)

{define} M(j, i) (m[j * {nqubits} + i])

template<{d_template}class T>
inline void kernel_core(T* psi, std::size_t I{d_var}, const T* m)
{{
    std::array v = {{{v_array}}};

    {psi_assign}
}}

{undef} M
""".format( \
        include    = "#include", \
        define     = "#define", \
        undef      = "#undef", \
        nqubits    = nqubits, \
        d_template = ''.join('std::size_t d{}, '.format(i) for i in range (0, nqubits)) if ids != None else '', \
        d_var      = ''.join(', std::size_t d{}'.format(i) for i in range (0, nqubits)) if ids == None else '', \
        v_array    = newline + ''.join('        {},{}'.format(strcombs[i], newline) for i in range(0, len(strcombs))) + '    ', \
        psi_assign = ''.join('{} = {};{}    '.format(strcombs[i], strrhs[i], newline) for i in range(0, len(strcombs)))) + \
f"""
{define} LOOP_COLLAPSE{nqubits} ({nqubits} + 1) 

// bit indices id[.] are given from high to low (e.g. control first for CNOT)
template<class T>
void kernel(T* psi, {''.join('unsigned id{}, '.format(nqubits - i - 1) for i in range (0, nqubits)) if ids == None else ''}const T* m, std::size_t ctrlmask)
{{
    {'constexpr ' if ids != None else ''}std::size_t d0 = 1UL << {'id0' if ids == None else ids[0]}{''.join(', d{} = 1UL << {}'.format(i, 'id{}'.format(i) if ids == None else ids[i]) for i in range (1, nqubits))};
    {'constexpr ' if ids != None else ''}std::size_t n = 1{''.join(' + d{}'.format(i) for i in range (0, nqubits))};
    {'constexpr ' if ids != None else ''}std::size_t dsorted[] = {{ d{nqubits - 1}{''.join(', d{}'.format(nqubits - i - 1) for i in range (1, nqubits))} }};
    {'std::sort(dsorted, dsorted + {}, std::greater<std::size_t>());{}'.format(nqubits, newline) if ids == None else ''}
    if (ctrlmask == 0){{
        {pragma} omp for collapse(LOOP_COLLAPSE{nqubits}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * dsorted[0]){{
{''.join('{}for (std::size_t i{} = 0; i{} < dsorted[{}]; i{} += 2 * dsorted[{}]){}'.format(''.join('    ' for j in range(0, i + 2)), i, i, i - 1, i, i, newline) for i in range (1, nqubits))}{''.join('    ' for i in range (0, nqubits + 2))}for (std::size_t i{nqubits} = 0; i{nqubits} < dsorted[{nqubits - 1}]; ++i{nqubits}){{
        {''.join('    '.format(i) for i in range (1, nqubits + 2))}kernel_core{'<d0' if ids != None else ''}{''.join(', d{}'.format(i) for i in range (1, nqubits)) if ids != None else ''}{'>' if ids != None else ''}(psi, i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))}, {''.join('d{}, '.format(i) for i in range (0, nqubits)) if ids == None else ''}m);
        {''.join('    '.format(i) for i in range (1, nqubits + 1))}}}
        }}
    }}
    else{{
        {pragma} omp for collapse(LOOP_COLLAPSE{nqubits}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * dsorted[0]){{
{''.join('{}for (std::size_t i{} = 0; i{} < dsorted[{}]; i{} += 2 * dsorted[{}]){}'.format(''.join('    ' for j in range(0, i + 2)), i, i, i - 1, i, i, newline) for i in range (1, nqubits))}{''.join('    ' for i in range (0, nqubits + 2))}for (std::size_t i{nqubits} = 0; i{nqubits} < dsorted[{nqubits - 1}]; ++i{nqubits}){{
        {''.join('    '.format(i) for i in range (1, nqubits + 2))}if (((i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))})&ctrlmask) == ctrlmask)
        {''.join('    '.format(i) for i in range (1, nqubits + 3))}kernel_core{'<d0' if ids != None else ''}{''.join(', d{}'.format(i) for i in range (1, nqubits)) if ids != None else ''}{'>' if ids != None else ''}(psi, i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))}, {''.join('d{}, '.format(i) for i in range (0, nqubits)) if ids == None else ''}m);
        {''.join('    '.format(i) for i in range (1, nqubits + 1))}}}
        }}
    }}
}}

{undef} LOOP_COLLAPSE{nqubits}

"""

    return kernel

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate Haener-Steiger quantum kernels in the form used in ProjectQ simulator')
    parser.add_argument('nqubits', type=int, help='The number of qubits to generate the kernel for')
    parser.add_argument('output', type=str, help='Output file name')
    args = parser.parse_args()
    
    nqubits = int(args.nqubits)
    output = args.output

    try:
        os.makedirs(os.path.dirname(output))
    except:
        pass
    with open(output, "w") as o:
        o.write(kernelgen(nqubits))

