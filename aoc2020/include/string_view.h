#ifndef STRING_VIEW_H
#define STRING_VIEW_H

#include <cassert>
#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <functional>
#include <iostream>
#include <string>

template <typename CharT>
class BasicStringView {
   public:
    constexpr BasicStringView() noexcept : data_(nullptr), size_(0U) {}
    constexpr BasicStringView(std::string const& str) noexcept
        : data_(str.c_str()), size_(str.length()) {}
    constexpr BasicStringView(const CharT* str) noexcept
        : data_(str), size_(str ? std::char_traits<CharT>::length(str) : 0) {}
    constexpr BasicStringView(const CharT* str, std::size_t size) noexcept
        : data_(str), size_(size) {}
    constexpr BasicStringView(const BasicStringView& other) noexcept
        : data_(other.data_), size_(other.size_) {}

    BasicStringView& operator=(const BasicStringView& other) = default;
    bool operator==(const BasicStringView& other) const {
        if (size_ != other.size()) {
            return false;
        } else {
            return memcmp(data_, other.data(), size_) == 0;
        }
    }

    constexpr const CharT* begin() const noexcept { return data_; }
    constexpr const CharT* end() const noexcept { return data_ + size_; }

    constexpr std::size_t size() const noexcept { return size_; }

    constexpr bool empty() const noexcept { return size_ == 0U; }

    constexpr const CharT* data() const noexcept { return data_; }

    constexpr const CharT& operator[](std::size_t pos) const {
        assert(pos < size_);
        return data_[pos];
    }

    BasicStringView take_mut(size_t n) {
        size_t forward = std::min<size_t>(n, size_);
        data_ += forward;
        size_ -= forward;

        return {data_ - forward, forward};
    }

    BasicStringView take(size_t n) {
        size_t forward = std::min<size_t>(n, size_);

        return {data_, forward};
    }

    void forward_mut(size_t n) {
        size_t seek = std::min<size_t>(n, size_);
        data_ += seek;
        size_ -= seek;
    }

    BasicStringView forward(size_t n) const {
        size_t seek = std::min<size_t>(n, size_);

        return {data_ + seek, size_ - seek};
    }

    BasicStringView trim_left() const {
        size_t i{0U};
        while (i < size_ && std::isspace(data_[i])) {
            i += 1;
        }

        return BasicStringView(data_ + i, size_ - i);
    }

    void trim_left_mut() {
        size_t i{0U};
        while (i < size_ && std::isspace(data_[i])) {
            i += 1;
        }

        data_ += i;
        size_ -= i;
    }

    BasicStringView chop_by_delim(CharT delim) {
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

    BasicStringView chop_by_sv(BasicStringView const delim) {
        BasicStringView window{data_, delim.size()};
        size_t i{0U};
        while (i + delim.size() < size_ && !(window == delim)) {
            i++;
            window.data_++;
        }

        size_t result_size{i};
        if (i + delim.size() == size_) {
            result_size += delim.size();
        }

        BasicStringView result{data_, result_size};

        data_ += i + delim.size();
        size_ -= i + delim.size();

        return result;
    }

    template <typename T>
    T chop_number() {
        T result{0};
        bool is_signed{false};
        if (*data_ == '-') {
            size_--;
            data_++;
            is_signed = true;
        } else if (*data_ == '+') {
            size_--;
            data_++;
        }
        while (size_ > 0 && isdigit(*data_)) {
            result = result * 10 + static_cast<T>(*data_ - '0');
            size_ -= static_cast<T>(1);
            data_ += static_cast<T>(1);
        }
        return is_signed ? result * -1 : result;
    }

    BasicStringView chop_while(std::function<bool(char x)> predicate) {
        size_t i{0U};
        while (i < size_ && predicate(data_[i])) {
            i += 1U;
        }
        BasicStringView result(data_, i);

        size_ -= i;
        data_ += i;

        return result;
    }

    uint64_t to_u64() const {
        uint64_t result{0U};
        for (std::size_t i{0U}; i < size_ && isdigit(data_[i]); ++i) {
            result = result * 10 + static_cast<uint64_t>(data_[i] - '0');
        }

        return result;
    }

    bool starts_with(BasicStringView const expected_prefix) const {
        if (expected_prefix.size() <= size_) {
            BasicStringView actual_prefix{data_, expected_prefix.size()};
            return expected_prefix == actual_prefix;
        }

        return false;
    }

    bool ends_with(BasicStringView const expected_suffix) const {
        if (expected_suffix.size() <= size_) {
            BasicStringView actual_suffix{
                data_ + size_ - expected_suffix.size(), expected_suffix.size()};
            return expected_suffix == actual_suffix;
        }
        return false;
    }

    BasicStringView substr(size_t start, size_t end) const {
        start = std::max<size_t>(0, start);
        end = std::min<size_t>(size_, end);

        BasicStringView result{data_ + start, end - start};

        return result;
    }

    std::string to_string() const { return std::string(data_, size_); }

   private:
    const CharT* data_;
    std::size_t size_;
};

using StringView = BasicStringView<char>;

#endif /* STRING_VIEW_H */
