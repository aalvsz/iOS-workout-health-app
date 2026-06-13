from fizzbuzz import fizzbuzz


def test_fizzbuzz_basic():
    result = fizzbuzz(15)
    assert result[0] == '1'
    assert result[2] == 'Fizz'
    assert result[4] == 'Buzz'
    assert result[14] == 'FizzBuzz'


def test_fizzbuzz_length():
    assert len(fizzbuzz(10)) == 10


def test_fizzbuzz_multiples_of_3():
    result = fizzbuzz(9)
    assert result[2] == 'Fizz'
    assert result[5] == 'Fizz'
    assert result[8] == 'Fizz'


def test_fizzbuzz_multiples_of_5():
    result = fizzbuzz(10)
    assert result[4] == 'Buzz'
    assert result[9] == 'Buzz'


def test_fizzbuzz_numbers_as_strings():
    result = fizzbuzz(2)
    assert result == ['1', '2']
