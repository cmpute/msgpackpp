import msgpack
import msgpackpp

def test_simple_roundtrip():
    pass

def test_int_roundtrip():
    powers = [1,2,7,8,15,16,31,32]
    bases = [2,3,5,7,11]
    test_cases = [0,1]
    for p in powers:
        for b in bases:
            test_cases.append(b ** p)
            test_cases.append(-b ** p)

    for case in test_cases:
        assert msgpackpp.pack(case) == msgpack.packb(case), str(case)

def test_float_roundtrip():
    test_cases = [0.0,1.0,-1.0,1e10,-1e10]
    for case in test_cases:
        assert msgpackpp.pack(case) == msgpack.packb(case), str(case)

def test_list_roundtrip():
    test_cases = [[], [0],[-2,-1,0,1,2]]
    for case in test_cases:
        assert msgpackpp.pack(case) == msgpack.packb(case), str(case)

def test_dict_roundtrip():
    test_cases = [{}, {0:0},{1:0,0:1}]
    for case in test_cases:
        assert msgpackpp.pack(case) == msgpack.packb(case), str(case)

def test_unsupported_type():
    class NewType:
        pass
    msgpackpp.pack(NewType())

if __name__ == "__main__":
    # test_int_roundtrip()
    test_float_roundtrip()
    test_list_roundtrip()
    test_dict_roundtrip()
    test_unsupported_type()
