;
; cJson.ahk 0.2.1
; Copyright (c) 2021 Philip Taylor (known also as GeekDude, G33kDude)
; https://github.com/G33kDude/cJson.ahk
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;

class cJson
{
	static version := "0.2.1"

	_init()
	{
		if (this.lib)
			return
		this.lib := this._LoadLib()

		; Populate globals
		NumPut(&this.True, this.lib.objTrue+0, "UPtr")
		NumPut(&this.False, this.lib.objFalse+0, "UPtr")
		NumPut(&this.Null, this.lib.objNull+0, "UPtr")

		this.fnGetObj := Func("Object")
		NumPut(&this.fnGetObj, this.lib.fnGetObj+0, "UPtr")
	}

	_LoadLib() {
		static CodeBase64 := ""
		. "TLUCAAwAVUiJ5UiDAOxwSIlNEEiJAFUYTIlFIEyJAE0oSItFEEiLAQAIRThIiwBIORDCD4S0ALjHRfwBAWrrR0iDfRgAAHQti0X8SJhIAI0VNRoA"
		. "AEQPFLYEAWAYAWCNSAIASItVGEiJCmYAQQ++0GaJEOsCDwA2IIsAjVABgQEIiRCDRfwBBT8Q9RkAAAE+hMB1EqUDek0gAT9JicgASInB6CYfAACF"
		. "A3EZEGDHACIADl0CuAGn6S4GAADGSEX7AANTUDADB0ASIABodVsADAHHRQr0Amg1hBAYi0X0AYBIweAFSAHQSJiJRdCAC4ABUBCACxiDwAEADQCF"
		. "lMCIAEX7g0X0AYB90PsAdBMBGWMBFAUtFHyyA1Ysgg8IQbjCWwExBkG4e4ADEGBERImPX8dF8IJgDhYFAhmETfCJTciDfdDwAH5eGYwsDyyZCxIg"
		. "jwsPtoA68AGEgMAPhNgBAACBIOXGOjABQ42BATUrZ0ABpsjAD415Px1FEhxUEszp9kNQCRPp4sAEyiWqOMIlsMKr7Myr7MKbtJYX8avswKvDD1bA"
		. "D1PIqxEzchyeRSxMGOvaG9QSRgZG0xI6vnkBDwAPtkAYPAF1HyeDEMAsahCiG6BRfALDwi9DBQYPhZRAQsUFADlFKHVpx0XoZQwu6AImLhYfLg8u"
		. "6JMALuMH7hUHLun2qg6qMKEO5KwO5KIGvaAGW78OrQ7koA7jB32pDoBVqg44oQ7grA7gogZNW78OsA7goA7jBw2pDgrBpw5Mi00oTKAFYgmAi004"
		. "SIlMJAC1FE0wAQEgYTQu+v9Y/+nYQ2RjNAXVOfOpILbprUJk3KwY3KIQbIwUvxivGNygGOMHTHfgB0tkTRBQgL4fhwwM8McADEh9wa0PjNvgHkyu"
		. "Gl1Ern1frkrGSIPEMHBdw5AFAO/lgexCMEEyjawkgMEFiaSNwMIAlcgCDYXBAIVgFxRlAUjHQAjiK+0gEIVCBQERUAARowFBbwHlAg+3AGaD+CBE"
		. "dNVNAgp0wk0CDUR0r00CCXScTQJ7MA+FKQPiElMPx0WiUEIPx0VYdABgcgBwiwUD/yAVMSdBcwWE9f7QAMdEJEBTAkhEJDiCAI1VsCdUVCQwgABQ"
		. "gQAokAEgUdARAEG58QFBEhW6QaICicFB/9LihIn8RWjPEM8QzxDPEM8QzxBhJwF9D4TC0jRpAYUFgG2sXgGD+CJ0CsK4IBD/6RYRgQ7AJgaJYAfC"
		. "Huj3/f//kIXAdCIDAvUQDxa/7wzvDO8M7wzvDCcBOhUK3nQPCAkIUijHCzrDC7QDljiyA/FEjQMsRWjUOf6ykAF/Go8Njw2PDY8Njw0xJwEsdR1v"
		. "B2MH6cLN0AuQjh3VDGoPnxCcEAWwOQm2OYtVaEiJNFAIs6ItygOTBVsPfIVlIm8/BfQzUppwAPindABSQhAzw/v5M7XRANn/M41VcJzzM/D/M/8z"
		. "heAZ2PAzcMeFrDAB/4ECHxofGh8aHxofGh8aJwHYXQ+EYbOfNN5HUCgnZsfgWScnxQ0xAuImi9aVcQxQDXBEJ50wGC8Nvy8NLw0vDS8NLw1JJyRv"
		. "B2VjB4PTFumqQFC+J135ZQ3uDH8ivye5J0DXtSfGscoDFEgPhRPCvz8FIcsQSImFoHgXi5UH0gCwBWcHCADpWQQVDxt1tAsy7wf4XA+chfavY+8H"
		. "1Qp1NCABe5IHcQKJQghCfB8EtDzHb+oFVAdvBGIEXG8EZQSA2W8E+C9vBGIEL28EZQTyOW8E+GJvBOQUbwRkBLby6kJjBGZvBGIEDG8EZWUEq28E"
		. "+G5vBGIECgtvBGUEZG0E77YAZoP4cnU0SIsAhaAAAABIjVAQAkiJlQFQZscA1A0AALDAAViLA2QENGCJEOkdAgFUBXAPVLcAAIx0FIwJF4zWwgEP"
		. "jHUPhYUKFgszgwRiAFcAAMeFnAAFOQEA6TsDMgEaAEbB4DgEicIFKQIzCmIvfuJCDRI5fy8HH4IdBw8gAdCD6DCJJ+muI4INiyBAfj8NCUZ/Siwa"
		. "KjcJKutcDR9gFY8oZpwoV4ooCrj/UQAA6WUIF6eDAqEBBIO9gQEDD464/hD//0iDQhAC6zqFww8lyQ8QSI1Kxw+qCEZ8SEB8jQMmEpBcICIPhZD7"
		. "gBaLhYrIggVIRg4pyEgCLYHDBUAISIPoBIt5JdUuuEJ+hwfPYi10Qi7OfA+ODAVPCjnQD4/1BEGSmIFBAxuLQSIAHhTFAkjHQEBAeVAZdSLDDUFJ"
		. "2KsKDTAudUFwkxVMx6vQHDAPBI6JkAU5f3brTAEGUVAISInQSMEA4AJIAdBIAcCYSYnAyRhAaouVwxgCCkAPSA+/wEwBasBgD9AFCIkACE5mHwlu"
		. "Dn6OJUwDBgAAwpDtAy4PhebYG0g+AGYP78DySA8qY8EUYQLyDxHgQAYxBYXAM5TEM+tsi5VhAQSJ0MAbAdABwIl7QgP4G5iAdwIM4AvgANID4AAi"
		. "CGYPKMjyDwReymYOEEAI8g8sWMFsEKwgFw9IjmoTyj/DAmV0LgVFD4Vu+Bub4Q5jBRSnRP8jBVAAxoWTE1QhIwMBiZUO6zJtBit1H64JMTtaL34T"
		. "T0MEQ+oDhWFrjKS06zqLlWEB7YY3QTpTITdEITxhBr8OIaAOoMeFiARFx4XihKUOHIuVoQJIRsEBUoMCBAGLwgA7Ygx8yNaAvUIfdCqpQsAvOsmg"
		. "Ro2hBiBGKkTrKCUnBUgDNQ8q4gvyD1ZZbUnpOySodYuiiEiQmEgPr2lw6zhqBlwFdXINQQd8DQxnRQOKAKOmURH4D4W3khMygJUTUouyAJAJjRUC"
		. "fRADD7YEEGYPRr5BCpgDOcJ05B77X/8tmGahBPAWFgUrFAWEmMB1lxcK4YIV5oMEGddIBdQSAcNNiwXGodEAicH/0tMMg3+EEPhmD4UBVMdFfKGi"
		. "DEyLRXxSB7qwAht/DHsMM38MdwxFfAGttQRutAQQDKAcDAQeDLby1AQTDOSCARYMwS8uoPhuD4WlEgx4EgzQSYtFeFIH/qEdHwxlEwwHEgzrdO8L"
		. "5Qt4W+ALgwS1hATgC6PsC1Urp3DkC0PqCzXqC+sFIVIHSIHEMGAPXcM+kAcApCQPAA8AAgAiVQBua25vd25fTwBiamVjdF8AIgGFAHRydWUAZmEA"
		. "bHNlAG51bGwBlwJWYWx1ZV8AADAxMjM0NTY3ADg5QUJDREVGAfMEVUiJ5UiDxACASIlNEEiJVQAYTIlFIMdF/A0DTkXATBFWKEiNTQAYSI1V/EiJ"
		. "VEAkKMdEJCDxAUFCuYFESYnIutMCTYAQ/9BIx0Xg0gAox0XodADwtAQgSDiJReDgAFOEogVMi0BQMItF/EgQBUBR0wJEJDiFADCCAI38VeBGB4CI"
		. "QAeiB2IVcZFgTRBB/9LRBTMhCfx1HqIGgZLCGGAG5ADRGMTrYKcCA3VTtQEBDGCASDnQfUBp1AK6RfAaf0IbOdB/4E5FmfEP2Elwg1MH6NMwAxCF"
		. "wHQPoAHYSIsKVVADUjAGEJBIg8zsgBge8xXsYPEV5BVAZsdF6gAAEAWJFEX4oBYVgASLTRiAicq4zczMzDBOAMJIweggicLBBOoDJlkpwYnKiQDQ"
		. "g8Awg238AQSJwjETmGaJVEUKwFEEwooDwegDiQBFGIN9GAB1qX8gCxACsAJQjrGOYAoYDAGzsKzgCsRgCSn0CnD/IJgA6a5CUZEbUBhjBYjB4AVx"
		. "BYlF0PEABmMQBtEBQDBIOcL4D42akB6wDsAVYAGgAQJAAAVF8MZF7wCASIN98AB5CKAA4AFI913wsCJBEEAJIPBIumdmAwBIiZDISPfqgpr4AkAm"
		. "gEnB+D9MKcDBC6HJm0gpwUi2EeiyER7osxEAl/8E9ARIwflSP2ADSCmxC/DiCHWAgIB97wB0EFEEQTMEx0RFkC0RKJAD8gA0FIlFwMZF52NQR3Iu"
		. "i0XgoUKxsEVR4QEPtxAkAQwhARhISAHIg0d1b68CAOBmhcB1HnkB8AJ1AToGUAYBEIFfA9ABdCIDXwNyAQqDReAB6QJmcCuQgH3nAA8khPbFN4tV"
		. "sAsQuFnRN+kBUAAKGzgBG4yGyrMCpRrIxkXfcA7q2HMO2OYGyHUOIgF/Du+uAnUOdwF7Dt9yDl8Dcw4LXwNzDth2Dt8AdBLBPQ7rIINF/IAcSA7C"
		. "IEIOO/3//9JDkC8ocF3D9C4w+S7GRQr/cA/4QgJcsgCDfRAAeQjGRQD/AUj3XRBIi0BNEEi6Z2YDAEgAichI9+pIidAASMH4AkmJyEkAwfg/TCnA"
		. "SIkCwgJM4AJIAdBIAAHASCnBSInKAInQjUgwi0X4AI1QAYlV+InKgEiYZolURdAYohBIwfk/AHBIKdAgSIlFEEgBiQ+FAHr///+Aff8ADHQSBksA"
		. "ScdERdAALQCDbfgB6zwBACgYAHQiSItFABhIiwBIjUgCAEiLVRhIiQqLAQAqY9IPt1RV0CBmiRDrDwAhIIsmAABDAQiJEAE9g31A+AB5vrgAAABI"
		. "AIPEMF3DkFVIAInlSIPsIEiJAYBTiVUYTIlFIAWDMByPMGbHACIAGOkIBIAeiy3p9AMBggkQD7cAZoP4KCJ1ZoMhGZIhXABbDk4cOZADLwo5fAo5"
		. "XKFKOVwA6R2QHAmKHAYIvxyIC2IA6aoCbY8clsMEhBwMvxyIC2aoAOk3kBwjihwKvxxBiAtuAOnEAY8csBvDBIQcDb8ciAtyAOnqUZAcPYocCV8O"
		. "Xw7GBbB0AOneQWxMDspjAhFEDh9+DYcBfn58N/8P8A/TBXXQBUMND7cawCCSIEEFAJqJwejSjGAS6zSDCR6PCcAAhcAGEvGJSINFEMAEASMYhcAP"
		. "hfz7/6r/uRIirxKQoJAgoJAvBwDlkQClpJFmgaONBQQd9aALiUXwx0UC/MGX6zIPt0UQiIPgD6Gxi0XwQLEAD7YAZg++0IsURfxjr+ghBGbB6CIE"
		. "IQiDRfygn/wDIH7Ix0X4wHgA6wo/YxUl4KxImEQPELdERejPFkSJwg16qbtlqaUY"
		static Code := false
		if ((A_PtrSize * 8) != 64) {
			Throw Exception("_LoadLib does not support " (A_PtrSize * 8) " bit AHK, please run using 64 bit AHK")
		}
		; MCL standalone loader https://github.com/G33kDude/MCLib.ahk
		; Copyright (c) 2021 G33kDude, CloakerSmoker (CC-BY-4.0)
		; https://creativecommons.org/licenses/by/4.0/
		if (!Code) {
			if !DllCall("Crypt32\CryptStringToBinary", "Str", CodeBase64, "UInt", 0, "UInt", 1, "UPtr", 0, "UInt*", CompressedSize, "Ptr", 0, "Ptr", 0, "UInt")
				throw Exception("Failed to parse MCLib b64 to binary")
			CompressedSize := VarSetCapacity(DecompressionBuffer, CompressedSize, 0)
			if !DllCall("Crypt32\CryptStringToBinary", "Str", CodeBase64, "UInt", 0, "UInt", 1, "Ptr", &DecompressionBuffer, "UInt*", CompressedSize, "Ptr", 0, "Ptr", 0, "UInt")
				throw Exception("Failed to convert MCLib b64 to binary")
			if !(pCode := DllCall("GlobalAlloc", "UInt", 0, "Ptr", 9808, "Ptr"))
				throw Exception("Failed to reserve MCLib memory")
			if (DllCall("ntdll\RtlDecompressBuffer", "UShort", 0x102, "Ptr", pCode, "UInt", 9808, "Ptr", &DecompressionBuffer, "UInt", CompressedSize, "UInt*", DecompressedSize, "UInt"))
				throw Exception("Error calling RtlDecompressBuffer",, Format("0x{:08x}", r))
			if !DllCall("VirtualProtect", "Ptr", pCode, "Ptr", 9808, "UInt", 0x40, "UInt*", OldProtect, "UInt")
				Throw Exception("Failed to mark MCLib memory as executable")
			Exports := {}
			for ExportName, ExportOffset in {"BIGINTS_AS_FLOATS": 0, "dumps": 16, "fnGetObj": 1840, "loads": 1856, "objFalse": 6752, "objNull": 6768, "objTrue": 6784} {
				Exports[ExportName] := pCode + ExportOffset
			}
			Code := Exports
		}
		return Code
	}

	Dumps(obj)
	{
		this._init()
		if (!IsObject(obj))
			throw Exception("Input must be object")
		size := 0
		DllCall(this.lib.dumps, "Ptr", &obj, "Ptr", 0, "Int*", size
		, "Ptr", &this.True, "Ptr", &this.False, "Ptr", &this.Null, "CDecl Ptr")
		VarSetCapacity(buf, size*2+2, 0)
		DllCall(this.lib.dumps, "Ptr", &obj, "Ptr*", &buf, "Int*", size
		, "Ptr", &this.True, "Ptr", &this.False, "Ptr", &this.Null, "CDecl Ptr")
		return StrGet(&buf, size, "UTF-16")
	}

	Loads(ByRef json)
	{
		this._init()

		_json := " " json ; Prefix with a space to provide room for BSTR prefixes
		VarSetCapacity(pJson, A_PtrSize)
		NumPut(&_json, &pJson, 0, "Ptr")

		VarSetCapacity(pResult, 24)

		if (r := DllCall(this.lib.loads, "Ptr", &pJson, "Ptr", &pResult , "CDecl Int")) || ErrorLevel
		{
			throw Exception("Failed to parse JSON (" r "," ErrorLevel ")", -1
			, Format("Unexpected character at position {}: '{}'"
			, (NumGet(pJson)-&_json)//2, Chr(NumGet(NumGet(pJson), "short"))))
		}

		result := ComObject(0x400C, &pResult)[]
		if (IsObject(result))
			ObjRelease(&result)
		return result
	}

	True[]
	{
		get
		{
			static _ := {"value": true, "name": "true"}
			return _
		}
	}

	False[]
	{
		get
		{
			static _ := {"value": false, "name": "false"}
			return _
		}
	}

	Null[]
	{
		get
		{
			static _ := {"value": "", "name": "null"}
			return _
		}
	}
}

