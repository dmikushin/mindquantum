#include "nointrin/kernels.hpp"

namespace generated {

#include "generated/nointrin/kernel1.hpp"
#include "generated/nointrin/kernel2.hpp"
#include "generated/nointrin/kernel3.hpp"
#include "generated/nointrin/kernel4.hpp"
#include "generated/nointrin/kernel5.hpp"

} // namespace generated

#include <array>

#include "gtest/gtest.h"

template<int nqubits>
bool compare()
{
	constexpr auto dim = 1UL << nqubits;
	
	// TODO Generate m matrix as integers.
	std::array<std::array<int, nqubits>, nqubits> m;
	
	// TODO Replace std::complex with auto.
	
	// TODO Generate id_0...id_nq integers (unsorted).
	
	// TODO Generate psi matrix as integers.
	
	// TODO Compare kernel against generated kernel
	return true;
}

TEST(nointrin, kernel1)
{
	ASSERT_TRUE(compare<1>);
}

TEST(nointrin, kernel2)
{
	ASSERT_TRUE(compare<2>);
}

TEST(nointrin, kernel3)
{
	ASSERT_TRUE(compare<3>);
}

TEST(nointrin, kernel4)
{
	ASSERT_TRUE(compare<4>);
}

TEST(nointrin, kernel5)
{
	ASSERT_TRUE(compare<5>);
}

int main(int argc, char* argv[])
{
	::testing::InitGoogleTest( & argc, argv);
	return RUN_ALL_TESTS();
}

