#!/usr/bin/env python3

nqubits = 3

pragma = "#pragma";
newline = "\n";

kernel = \
f"""
template <class V, class M>
inline void kernel_core(V &psi, std::size_t I, std::size_t d0{''.join(', std::size_t d{}'.format(i) for i in range (1, nqubits))}, M const& m)
{{
    std::array<std::complex<double>, 1U << nqubits> v;
    v[0] = psi[I];
    v[1] = psi[I + d0];

    nqubits = 2:
    
    v[0] = psi[I];
    v[1] = psi[I + d0];
    v[2] = psi[I + d1];
    v[3] = psi[I + d0 + d1];    

    // All combinations of qubits, excluding dupes:
    v[0] = 0 0
    v[1] = 1 0
    v[2] = 0 1
    v[3] = 1 1

    psi[I] = (add(mul(v[0], m[0][0]), mul(v[1], m[0][1])));
    psi[I + d0] = (add(mul(v[0], m[1][0]), mul(v[1], m[1][1])));
}}

// bit indices id[.] are given from high to low (e.g. control first for CNOT)
template <class V, class M>
void kernel(V &psi, {''.join('unsigned id{}, '.format(i) for i in range (0, nqubits))}M const& m, std::size_t ctrlmask)
{{
    std::size_t n = psi.size();
    std::size_t d0 = 1UL << id0{''.join(', d{} = 1UL << id{}'.format(i, i) for i in range (1, nqubits))};
    std::size_t dsorted[] = {{ d0{''.join(', d{}'.format(i) for i in range (1, nqubits))} }};
    std::sort(dsorted, dsorted + {nqubits}, std::greater<std::size_t>());

    if (ctrlmask == 0){{
        {pragma} omp for collapse(LOOP_COLLAPSE{nqubits}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * dsorted[0]){{
{''.join('{}for (std::size_t i{} = 0; i{} < dsorted[{}]; i{} += 2 * dsorted[{}]){}'.format(''.join('    ' for j in range(0, i + 2)), i, i, i - 1, i, i, newline) for i in range (1, nqubits))}{''.join('    ' for i in range (0, nqubits + 2))}for (std::size_t i{nqubits} = 0; i{nqubits} < dsorted[{nqubits - 1}]; ++i{nqubits}){{
        {''.join('    '.format(i) for i in range (1, nqubits + 2))}kernel_core(psi, i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))}, {''.join('d{}, '.format(i) for i in range (0, nqubits))}m);
        {''.join('    '.format(i) for i in range (1, nqubits + 1))}}}
        }}
    }}
    else{{
        {pragma} omp for collapse(LOOP_COLLAPSE{nqubits}) schedule(static)
        for (std::size_t i0 = 0; i0 < n; i0 += 2 * dsorted[0]){{
{''.join('{}for (std::size_t i{} = 0; i{} < dsorted[{}]; i{} += 2 * dsorted[{}]){}'.format(''.join('    ' for j in range(0, i + 2)), i, i, i - 1, i, i, newline) for i in range (1, nqubits))}{''.join('    ' for i in range (0, nqubits + 2))}for (std::size_t i{nqubits} = 0; i{nqubits} < dsorted[{nqubits - 1}]; ++i{nqubits}){{
        {''.join('    '.format(i) for i in range (1, nqubits + 2))}if (((i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))})&ctrlmask) == ctrlmask)
        {''.join('    '.format(i) for i in range (1, nqubits + 3))}kernel_core(psi, i0{''.join(' + i{}'.format(i) for i in range (1, nqubits + 1))}, {''.join('d{}, '.format(i) for i in range (0, nqubits))}m);
        {''.join('    '.format(i) for i in range (1, nqubits + 1))}}}
        }}
    }}
}}
"""

print(kernel)

