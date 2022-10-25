#include "tempfile.h"

#include <errno.h>
#if __has_include(<version>)
#  include <version>
#endif
#if __has_include(<filesystem>) && __cpp_lib_filesystem >= 201703
#include <filesystem>
namespace fs = std::filesystem;
#else
#include <boost/filesystem.hpp>
namespace fs = boost::filesystem;
#endif
#include <vector>
#include <unistd.h>

const std::string& TempFile::string(std::error_code& ec_) const
{
	ec_ = ec;
	return filename;
}

TempFile::TempFile(const std::string& mask_)
{
	auto dir = fs::temp_directory_path(ec);
	if (ec) return; 

	std::string mask = (dir / mask_).string();

	std::vector<char> vfilename(mask.c_str(), mask.c_str() + mask.size() + 1);
	int fd = mkstemp(&vfilename[0]);
	if (fd == -1)
	{
		ec = std::error_code(errno, std::generic_category());
		return;
	}

	close(fd);
	filename = (char*)&vfilename[0];
}

TempFile::~TempFile()
{
	bool keepCache = false;
	const char* keepCacheValue = getenv("KEEP_CACHE");
	if (keepCacheValue)
		keepCache = atoi(keepCacheValue);
	if (!keepCache)
		unlink(filename.c_str());
}

