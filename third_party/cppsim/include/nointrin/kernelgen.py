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
            return f'add(mul(v_{i}, M({j}, {i})), ' + rhs(n, j, i + 1)
        else:
            return f'mul(v_{i}, M({j}, {i})' + ''.join(')' for k in range(0, n))

    # Pretty-print the right hand sides (recursively).
    strrhs = [] 
    for j in range(0, len(strcombs)):
        strrhs.append(rhs(len(strcombs), j, 0))

    ids_sorted = []
    if ids != None:
    	ids_sorted = sorted(ids, reverse = True)

    # Some string constants clash with the {} syntax of print(), so we
    # substitute them as constants.
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
    {v_assign}
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
        v_assign    = ''.join('const auto v_{} = {};{}{}'.format(i, strcombs[i], newline, ' ' * 4) for i in range(0, len(strcombs))), \
        psi_assign = ''.join('{} = {};{}    '.format(strcombs[i], strrhs[i], newline) for i in range(0, len(strcombs)))) + \
"""
// bit indices id[.] are given from high to low (e.g. control first for CNOT)
template<class T>
void kernel(T* psi, {id_var}const T* m, std::size_t ctrlmask)
{{
    {constexpr}std::size_t {d};
    {constexpr}std::size_t {n};
    {constexpr}std::size_t {dsorted};
    {sort}
    if (ctrlmask == 0){{
        {pragma} omp for collapse({collapse}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * {dsorted_0}){{
{for_loops}{offset_2}for (std::size_t i{nqubits} = 0; i{nqubits} < {dsorted_last}; ++i{nqubits}){{
        {offset_1}kernel_core{d_template}(psi, {i}, {d_args}m);
        {offset}}}
        }}
    }}
    else{{
        {pragma} omp for collapse({collapse}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * {dsorted_0}){{
{for_loops}{offset_2}for (std::size_t i{nqubits} = 0; i{nqubits} < {dsorted_last}; ++i{nqubits}){{
        {offset_1}if ((({i})&ctrlmask) == ctrlmask)
        {offset_2}kernel_core{d_template}(psi, {i}, {d_args}m);
        {offset}}}
        }}
    }}
}}

{undef} add
{undef} mul

""".format( \
        define      = "#define", \
        undef       = "#undef", \
        pragma      = "#pragma", \
        nqubits     = nqubits, \
        id_var      = ''.join('unsigned id{}, '.format(nqubits - i - 1) for i in range (0, nqubits)) if ids == None else '', \
        constexpr   = 'constexpr ' if ids != None else '',
        d           = f"d0 = 1UL << {'id0' if ids == None else ids[0]}{''.join(', d{} = 1UL << {}'.format(i, 'id{}'.format(i) if ids == None else ids[i]) for i in range (1, nqubits))}", \
        d_args      = ''.join('d{}, '.format(i) for i in range (0, nqubits)) if ids == None else '', \
        n           = 'n = 1' + ''.join(' + d{}'.format(i) for i in range (0, nqubits)), \
        dsorted     = (f"dsorted[] = {{ d{nqubits - 1}" + ''.join(', d{}'.format(nqubits - i - 1) for i in range (1, nqubits)) + f" }}") if ids == None else (f"dsorted0 = 1UL << {ids_sorted[0]}{''.join(', dsorted{} = 1UL << {}'.format(i, ids_sorted[i]) for i in range (1, nqubits))}"), \
        dsorted_0    = "dsorted[0]" if ids == None else "dsorted0", \
        dsorted_last = f"dsorted[{nqubits - 1}]" if ids == None else f"dsorted{nqubits - 1}", \
        sort        = f'std::sort(dsorted, dsorted + {nqubits}, std::greater<std::size_t>());{newline}' if ids == None else '', \
        collapse    = f"{nqubits + 1}", \
        offset    = ''.join('    '.format(i) for i in range (0, nqubits)), \
        offset_1    = ''.join('    '.format(i) for i in range (0, nqubits + 1)), \
        offset_2    = ''.join('    '.format(i) for i in range (0, nqubits + 2)), \
        d_template  = ('<d0' + ''.join(', d{}'.format(i) for i in range (1, nqubits)) + '>') if ids != None else '', \
        i           = 'i0' + ''.join(' + i{}'.format(i) for i in range (1, nqubits + 1)), \
        for_loops   = ''.join('{}for (std::size_t i{} = 0; i{} < dsorted{left}{}{right}; i{} += 2 * dsorted{left}{}{right}){}'.format(''.join('    ' for j in range(0, i + 2)), i, i, i - 1, i, i, newline,
            left  = '[' if ids == None else '', \
            right = ']' if ids == None else '') for i in range (1, nqubits)))

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

