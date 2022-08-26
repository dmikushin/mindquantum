#ifndef COMBINATIONS_H
#define COMBINATIONS_H

#define COMBINATIONS_RETVAL(expr) \
	if constexpr (std::is_same<Result, bool>::value) \
	{ \
		if (!(expr)) return false; \
	} \
	else \
		expr;

#define COMBINATIONS_RETVAL_TRUE() \
	if constexpr (std::is_same<Result, bool>::value) \
		return true; \

#include "gpu_support.h"

#include <algorithm>
#include <array>
#include <cstdio>
#include <stdint.h>
#include <type_traits>

namespace combinations {

// Iterate through the combinations using currying approach: https://stackoverflow.com/a/54508163/4063520
class Combinations
{
// *****************************************************************************
// Simple case: no sum constraint
// *****************************************************************************
private :

	template<
		uint32_t k, // length of sequence
		uint32_t m, // max allowed sequence element value
		typename Result = void, // use bool return type to continue or stop
		class Callable
	>
	GPU_SUPPORT
	static constexpr Result _iterate(Callable&& c)
	{
		static_assert(k > 0);
		for (uint32_t i = 0; i <= m; i++)
		{
			if constexpr(k == 1)
			{
				COMBINATIONS_RETVAL( c(i) );
			}
			else
			{
				auto bind_an_argument = [i, &c](auto... args)
				{
					COMBINATIONS_RETVAL(( c(i, args...) ));
					COMBINATIONS_RETVAL_TRUE();
				};

				COMBINATIONS_RETVAL(( _iterate<k - 1, m, Result>(bind_an_argument) ));
			}
		}
		
		COMBINATIONS_RETVAL_TRUE();
	}

public :

	template<
		uint32_t k, // length of sequence
		uint32_t m  // max allowed sequence element value
	>
	struct Combination
	{
		using type = std::array<uint32_t, k>;
	};

	// Iterate through all combinations.
	// For each combination, call a user-provided function.
	template<
		uint32_t k, // length of sequence
		uint32_t m, // max allowed sequence element value
		typename Result = void, // use bool return type to continue or stop
		class Callable
	>
	GPU_SUPPORT
	static constexpr Result iterate(Callable&& c)
	{
		COMBINATIONS_RETVAL(( _iterate<k, m, Result>(c) ));
		COMBINATIONS_RETVAL_TRUE();
	}

	// Tell the length of a combination supplied by the iterator
	// configured with the given set of template parameters.
	template<
		uint32_t k, // length of sequence
		uint32_t m  // max allowed sequence element value
	>
	static constexpr uint32_t length()
	{
		return k;
	}

	// Tell the number of combinations supplied by the iterator
	// configured with the given set of template parameters.
	template<
		uint32_t k, // length of sequence
		uint32_t m  // max allowed sequence element value
	>
	static uint32_t popcount()
	{
		if (k == 0) return 0;

		uint32_t result = 1;
		for (int i = 0; i < k; i++)
			result *= m + 1;

		return result;
	}

	// Tell the number of combinations supplied by the iterator
	// configured with the given set of runtime parameters.
	static uint32_t popcount(
		const uint32_t k, // length of sequence
		const uint32_t m) // max allowed sequence element value
	{
		if (k == 0) return 0;

		uint32_t result = 1;
		for (int i = 0; i < k; i++)
			result *= m + 1;

		return result;
	}

	// Reverse the order of elements in a combination
	// configured with the given set of template parameters.	
	template<
		uint32_t k, // length of sequence
		uint32_t m  // max allowed sequence element value
	>
	static void reverse(typename Combination<k, m>::type& c)
	{
		std::reverse(c.begin(), c.end());
	}

	// Reverse the order of elements in a combination
	// configured with the given set of runtime parameters.	
	static void reverse(
		const uint32_t k, // length of sequence
		const uint32_t m, // max allowed sequence element value
		uint32_t* c)
	{
		std::reverse(c, c + k);
	}

// *****************************************************************************
// Simple case: no sum constraint with a user-defined range
// *****************************************************************************
public :

	template<
		uint32_t k, // length of sequence
		uint32_t m, // max allowed sequence element value
		typename Result = void, // use bool return type to continue or stop
		class Callable
	>
	GPU_SUPPORT
	static constexpr Result _iterate(uint32_t* start, uint32_t& limit, Callable&& c)
	{
		static_assert(k > 0);
		for (uint32_t i = start[k - 1]; (i <= m) && limit; i++)
		{
			// Flush starting point to zero, in order for all subsequent iterations
			// to start from zero as usual.
			start[k - 1] = 0;

			if constexpr(k == 1)
			{
				COMBINATIONS_RETVAL( c(i) );
				limit--;
			}
			else
			{
				auto bind_an_argument = [i, &c](auto... args)
				{
					COMBINATIONS_RETVAL(( c(i, args...) ));
					COMBINATIONS_RETVAL_TRUE();
				};

				COMBINATIONS_RETVAL(( _iterate<k - 1, m, Result>(start, limit, bind_an_argument) ));
			}
		}
		
		COMBINATIONS_RETVAL_TRUE();
	}

public :

	// Iterate through combinations with specific starting point and duration.
	// For each combination, call a user-provided function.
	template<
		uint32_t k, // length of sequence
		uint32_t m, // max allowed sequence element value
		typename Result = void, // use bool return type to continue or stop
		class Callable
	>
	GPU_SUPPORT
	static constexpr Result iterate(const std::array<uint32_t, k>& start_, const uint32_t limit_, Callable&& c)
	{
		std::array<uint32_t, k> start = start_;
		uint32_t limit = limit_;
		COMBINATIONS_RETVAL(( _iterate<k, m, Result>(start.data(), limit, c) ));
		COMBINATIONS_RETVAL_TRUE();
	}

	// Tell the number of combinations supplied by the iterator
	// configured with the given set of template parameters.
	template<
		uint32_t k, // length of sequence
		uint32_t m  // max allowed sequence element value
	>
	static uint32_t popcount(const uint32_t limit)
	{
		// TODO Actually could be less than limit, if start is closer to the end.
		return limit;
	}

	// Tell the number of combinations supplied by the iterator
	// configured with the given set of runtime parameters.
	static uint32_t popcount(
		const uint32_t k, // length of sequence
		const uint32_t m, // max allowed sequence element value
		const uint32_t limit)
	{
		// TODO Actually could be less than limit, if start is closer to the end.
		return limit;
	}
};

} // namespace combinations

#endif // COMBINATIONS_H

