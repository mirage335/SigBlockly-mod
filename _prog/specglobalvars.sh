export generatorTemplate=python
export generatorSource="$scriptAbsoluteFolder"/_lib/blockly/generators/"$generatorTemplate"
export generatorSourceEntry="$scriptAbsoluteFolder"/_lib/blockly/generators/"$generatorTemplate".js

export scriptModules="$scriptLib"/modules

export splice="$scriptModules"/splice
export spliceUnidiff="$scriptModules"/splice/unidiff

export spliceTmp="$safeTmp"/splice
export spliceTmpUnidiff="$spliceTmp"/unidiff

export blockly_orig="$scriptLib"/blockly
export SigBlockly_mod="$scriptLib"/SigBlockly

_prepare_splice() {
	mkdir -p "$spliceTmp"
	mkdir -p "$spliceTmpUnidiff"
}

