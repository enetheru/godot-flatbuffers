
$flatc = 'C:\git\flatbuffers\cmake-build-debug\flatc.exe'

Get-ChildItem "./" -Filter *.fbs | 
Foreach-Object {
    & $flatc --gdscript $_ 
}
