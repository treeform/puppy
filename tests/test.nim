import puppy

doAssert fetch("www.istrolid.com", headers = @[("Auth", "1")]).len != 0
doAssert fetch("http://neverssl.com/").len != 0
doAssert fetch("https://blog.istrolid.com/").len != 0
