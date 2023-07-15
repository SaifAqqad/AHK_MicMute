; UTF-16LE Base64 encode/decode 
; By tmplinshi (https://github.com/tmplinshi)
; https://gist.github.com/tmplinshi/3776c215152436c6f1d722e0151d2fcb
class B64
{
	encode(ByRef sText)
	{
		ele := ComObjCreate("Msxml2.DOMDocument").CreateElement("aux")
		ele.DataType := "bin.base64"
		ele.NodeTypedValue := this.strToBytes(sText, "utf-16le", 2)
		return ele.Text
	}

	decode(ByRef sBase64EncodedText)
	{
		ele := ComObjCreate("Msxml2.DOMDocument").CreateElement("aux")
		ele.DataType := "bin.base64"
		ele.Text := sBase64EncodedText
		return this.bytesToStr(ele.NodeTypedValue, "utf-16le")
	}

	strToBytes(ByRef sText, sEncoding, iBomByteCount)
	{
		oADO := ComObjCreate("ADODB.Stream")

		oADO.Type := 2 ; adTypeText
		oADO.Mode := 3 ; adModeReadWrite
		oADO.Open
		oADO.Charset := sEncoding
		oADO.WriteText(sText)

		oADO.Position := 0
		oADO.Type := 1 ; adTypeBinary
		oADO.Position := iBomByteCount ; skip the BOM
		return oADO.Read, oADO.Close
	}

	bytesToStr(byteArray, sTextEncoding)
	{
		oADO := ComObjCreate("ADODB.Stream")

		oADO.Type := 1 ; adTypeBinary
		oADO.Mode := 3 ; adModeReadWrite
		oADO.Open
		oADO.Write(byteArray)

		oADO.Position := 0
		oADO.Type := 2 ; adTypeText
		oADO.Charset  := sTextEncoding
		return oADO.ReadText, oADO.Close
	}
}
