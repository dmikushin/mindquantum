#ifndef COMBINATIONS_SCHEDULE_H
#define COMBINATIONS_SCHEDULE_H

#include "combinations/sum_equal/combinations.h"
#include "combinations/sum_less_or_equal/combinations.h"
#include "earnest/sum_equal/earnest.h"
#include "earnest/sum_less_or_equal/earnest.h"

#if defined(__CUDACC__) || defined(__HIPCC__)
#include "combinations/distributed/gpu/schedule.h"
#endif
#include "combinations/distributed/cpu/schedule.h"

enum BackendPreference
{
	BackendNoPreference = 0,
	BackendPreferCPU = 1,
	BackendPreferDiscreteGPU = 2,
	BackendPreferIntegratedGPU = 3
};

namespace combinations {

namespace distributed {

namespace detail {

template<
	typename CombinationsT,
	typename Earnest,
	BackendPreference backend = BackendNoPreference>
class Schedule
{
public :

	using Combinations = CombinationsT;

	// Iterate through combinations with specific starting point and duration.
	// For each combination, call a user-provided function.
	template<
		class Contexts,
		uint32_t ...Args, // Underlying combination parameters
		class Callable
	>
	static auto schedule(Callable c, int nworkers = 0)
	{
		if constexpr (backend == BackendNoPreference)
		{
			// Prioritize GPU execution, if supported.
#if defined(__CUDACC__) || defined(__HIPCC__)
			return combinations::distributed::gpu::make_schedule<
				Contexts,
				Combinations,
				Earnest,
				Args...>(c, nworkers);
#else
			return combinations::distributed::cpu::make_schedule<
				Contexts,
				Combinations,
				Earnest,
				Args...>(c, nworkers);
#endif
		}
#if defined(__CUDACC__) || defined(__HIPCC__)
		else if constexpr (backend == BackendPreferDiscreteGPU)
		{
			return combinations::distributed::gpu::make_schedule<
				Contexts,
				Combinations,
				Earnest,
				Args...>(c, nworkers);
		}
#endif
		else if constexpr (backend == BackendPreferCPU)
		{
			return combinations::distributed::cpu::make_schedule<
				Contexts,
				Combinations,
				Earnest,
				Args...>(c, nworkers);
		}
		else
		{
			throw std::invalid_argument("Unsupported backend");
		}
	}

	template<typename Contexts, typename Schedule>
	static void iterate(Contexts& ctxs, Schedule& schedule)
	{
		schedule.execute(ctxs);
	}
};

} // namespace detail

template<
	BackendPreference backend = BackendNoPreference>
using Schedule = detail::Schedule<
	combinations::Combinations,
	earnest::Earnest,
	backend>;

namespace sum_equal {

template<
	BackendPreference backend = BackendNoPreference>
using Schedule = detail::Schedule<
	combinations::sum_equal::Combinations,
	earnest::sum_equal::Earnest,
	backend>;

} // namespace sum_equal

namespace sum_less_or_equal {

template<
	BackendPreference backend = BackendNoPreference>
using Schedule = detail::Schedule<
	combinations::sum_less_or_equal::Combinations,
	earnest::sum_less_or_equal::Earnest,
	backend>;

} // namespace sum_equal

} // namespace distributed

} // namespace combinations

#endif // COMBINATIONS_SCHEDULE_H

