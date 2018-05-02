##### Core

_construct_generator_sequence() {
	_start
	
	local localFunctionEntryPWD
	localFunctionEntryPWD="$PWD"
	
	local generatorName
	generatorName="$1"
	local generatorTemplate
	generatorTemplate=Python
	
	local generatorSource
	generatorSource="$scriptAbsoluteFolder"/lib/blockly/generators/"$generatorTemplate"
	local generatorDestination
	generatorDestination="$scriptLocal"/templates/"$generatorName"
	
	mkdir "$generatorDestination"
	
	cp -a  "$generatorSource"/. "$generatorDestination"/
	
	
	cd "$generatorDestination"/
	
	
	#Patch.
	
	
	
	cd "$localFunctionEntryPWD"
	_stop
}

