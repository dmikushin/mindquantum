#ifndef COMBINATIONS_PARTITIONER_H
#define COMBINATIONS_PARTITIONER_H 

#include "earnest/earnest.h"
#include "earnest/sum_equal/earnest.h"
#include "earnest/sum_less_or_equal/earnest.h"

#include <cstdio>

namespace combinations {

namespace distributed {

template<
	class Combinations,
	class Earnest
>
class Partitioner
{
public :

	template<
		uint32_t ...Args, // Underlying combination parameters
		class Starts
	>
	static void partition(Starts& starts, int& nworkers, uint32_t& maxCombinationsPerWorker)
	{
		using Combination = typename Combinations::template Combination<Args...>::type;

		uint32_t totalNumberOfCombinations = Combinations::template popcount<Args...>();
		maxCombinationsPerWorker = totalNumberOfCombinations / nworkers;
		if (totalNumberOfCombinations % nworkers) maxCombinationsPerWorker++;

		// Record starting points for workers' cooperative processing.
		starts.reserve(nworkers);
		uint32_t i = maxCombinationsPerWorker;
		Combinations::template iterate<Args...>([&](auto... args)
		{
			if (i < maxCombinationsPerWorker)
			{
				i++;
				return;
			}

			// Combinations::iterate uses reversed order of starting point indices.
			// We revert it here, in order to make the Combinations::iterate
			// code more generic.
			Combination start { args... };
			Combinations::template reverse<Args...>(start);
			starts.push_back(start);
			i = 1;
		});

		// Re-evaluate the number of workers, as their number could be eventually
		// smaller than the initially proposed number of workers.
		nworkers = starts.size();

		printf("%u iterations in total, %u workers, %u iterations per worker\n",
			totalNumberOfCombinations, nworkers, maxCombinationsPerWorker);
	}

	template<
		typename Args, // Underlying combination parameters
		class Starts
	>
	static void partition(Args& args, Starts& starts, int& nworkers, uint32_t& maxCombinationsPerWorker)
	{
		uint32_t totalNumberOfCombinations = std::apply([&](auto &&... args)
		{
			return Combinations::popcount(args...);
		},
		args);
		maxCombinationsPerWorker = totalNumberOfCombinations / nworkers;
		if (totalNumberOfCombinations % nworkers) maxCombinationsPerWorker++;

		// Record starting points for workers' cooperative processing.
		starts.reserve(nworkers);
		for (uint32_t i = 0; i < totalNumberOfCombinations; i += maxCombinationsPerWorker)
		{
			auto start = std::apply([&](auto &&... args)
			{
				return Earnest::template sequence(args..., i);
			},
			args);

			// Combinations::iterate uses reversed order of starting point indices.
			// We revert it here, in order to make the Combinations::iterate
			// code more generic.
			std::apply([&](auto &&... args)
			{
				Combinations::template reverse(args..., start.data());
			},
			args);
			for (auto element : start)
				starts.push_back(element);
		}

		// Re-evaluate the number of workers, as their number could be eventually
		// smaller than the initially proposed number of workers.
		nworkers = starts.size();

		printf("%u iterations in total, %u workers, %u iterations per worker\n",
			totalNumberOfCombinations, nworkers, maxCombinationsPerWorker);
	}

};

} // namespace distributed

} // namespace combinations

#endif // COMBINATIONS_PARTITIONER_H

