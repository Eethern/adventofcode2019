#ifndef STRING_VIEW_H
#define STRING_VIEW_H

#include <cctype>
#include <cstdint>
#include <cstddef>
#include <string>

template <typename CharT>
class BasicStringView
{
public:
    constexpr BasicStringView() noexcept : data_(nullptr), size_(0U) {}
    constexpr BasicStringView(const CharT* str) noexcept
        : data_(str)
        , size_(str ? std::char_traits<CharT>::length(str) : 0) {}
    constexpr BasicStringView(const CharT* str, std::size_t size) noexcept
        : data_(str)
        , size_(size) {}
    constexpr BasicStringView(const BasicStringView& other) noexcept
        : data_(other.data_)
        , size_(other.size_) {}

    BasicStringView& operator=(const BasicStringView& other) = default;

    constexpr const CharT* begin() const noexcept {
        return data_;
    }
    constexpr const CharT* end() const noexcept {
        return data_ + size_;
    }

    constexpr std::size_t size() const noexcept {
        return size_;
    }

    constexpr bool empty() const noexcept {
        return data_;
    }

    constexpr const CharT* data() const noexcept {
        return data_;
    }

    constexpr const CharT& operator[](std::size_t pos) const {
        return data_[pos];
    }

    BasicStringView trim_left() const
    {
        size_t i{0U};
        while (i < size_ && std::isspace(data_[i])) {
            i += 1;
        }

        return BasicStringView(data_ + i, size_ - i);
    }

    BasicStringView chop_by_delim(CharT delim)
    {
        size_t i{0U};
        while (i < size_ && data_[i] != delim) {
            i += 1;
        }

        BasicStringView result(data_, i);

        if (i < size_) {
            size_ -= i + 1;
            data_ += i + 1;
        } else {
            size_ -= i;
            data_ += i;
        }

        return result;
    }

private:
    const CharT* data_;
    std::size_t size_;
};

using StringView = BasicStringView<char>;

#endif /* STRING_VIEW_H */
