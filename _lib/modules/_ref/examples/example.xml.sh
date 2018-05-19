#test=""
#next2=""
#item=""
#i=""

#Describe this function...
function testFunction() {
  local test
  local next2
  test="$1"
  next2="$2"
  shift
  shift
  "$test" "$next2" "$@"
  return 123
}


export item='x'
testFunction echo 'abc' arbitraryInput

true

item+=('test1')
item+=("test2")
item+=('test3')
for i in "${item[@]}"
do
  echo "$i"
  echo $i
done
echo $(echo 'test' | cat) | cat
case 123 in
  123)
    echo 'abc'
  ;&
  *)
    echo 'xyz'
  ;;
esac


exit
<xml xmlns="http://www.w3.org/1999/xhtml">
  <variables>
    <variable type="" id="]{_/kd3QdWO*2h]Rglo~">test</variable>
    <variable type="" id="tp%WF}Kqc/cYYiuZMiN@">next</variable>
    <variable type="" id="/0,uM8CPLss/WG`)`!mI">item</variable>
    <variable type="" id="_8m`2v87#x,S1Cosh{L%">i</variable>
  </variables>
  <block type="procedures_defreturn" id="KZzYxU2OXMW|*]?-Zcn?" x="138" y="113">
    <mutation>
      <arg name="test" varid="]{_/kd3QdWO*2h]Rglo~"></arg>
      <arg name="next" varid="tp%WF}Kqc/cYYiuZMiN@"></arg>
    </mutation>
    <field name="NAME">testFunction</field>
    <comment pinned="false" h="80" w="160">Describe this function...</comment>
    <statement name="STACK">
      <block type="bash_local" id="}ux+ajkenVl{Z/~?,he`">
        <value name="NAME">
          <block type="variables_get" id="8Jz#,Kn~OW6b[Y1u};.K">
            <field name="VAR" id="]{_/kd3QdWO*2h]Rglo~" variabletype="">test</field>
          </block>
        </value>
        <next>
          <block type="bash_local" id="?{N`O:G}@i|Irpksn3Z3">
            <value name="NAME">
              <block type="variables_get" id="C/B6{@*BE?mmni,W;CB/">
                <field name="VAR" id="tp%WF}Kqc/cYYiuZMiN@" variabletype="">next</field>
              </block>
            </value>
            <next>
              <block type="variables_set" id="fNf2dbc2}m;f]@^/S$1O">
                <field name="VAR" id="]{_/kd3QdWO*2h]Rglo~" variabletype="">test</field>
                <value name="VALUE">
                  <block type="bash_specvar" id="O`R98oHj/IT!3(nN]*JC">
                    <field name="NAME">1</field>
                  </block>
                </value>
                <next>
                  <block type="variables_set" id="+KQf/+nw^%$?jP_1J;6J">
                    <field name="VAR" id="tp%WF}Kqc/cYYiuZMiN@" variabletype="">next</field>
                    <value name="VALUE">
                      <block type="bash_specvar" id="*Jnzb4$Hi?i#kp;e2ojj">
                        <field name="NAME">2</field>
                      </block>
                    </value>
                    <next>
                      <block type="arbitrary_code" id="Bipq^F#LV;rEpB_Z(V_2">
                        <field name="arbitraryCode">shift</field>
                        <next>
                          <block type="arbitrary_code" id="rgJ7VX|P#~l#Y*`C(}l1">
                            <field name="arbitraryCode">shift</field>
                            <next>
                              <block type="bash_functions_arg" id="Ag[Eqho4y8h;7fOm^*UW">
                                <field name="punctuation"> </field>
                                <value name="data">
                                  <block type="bash_deref" id="%B#{]Y}Xz^KVHi2vZL_z">
                                    <value name="source">
                                      <block type="variables_get" id="Az%U;+RW~L+vcv^;Q-kv">
                                        <field name="VAR" id="]{_/kd3QdWO*2h]Rglo~" variabletype="">test</field>
                                      </block>
                                    </value>
                                  </block>
                                </value>
                                <next>
                                  <block type="bash_functions_arg" id="jN%d/os0~Qnv[07P81EU">
                                    <field name="punctuation"> </field>
                                    <value name="data">
                                      <block type="bash_deref" id=".{pC|.ZGINaACzG?sDx}">
                                        <value name="source">
                                          <block type="variables_get" id="x*_=A0ldvGG6V`I%97~i">
                                            <field name="VAR" id="tp%WF}Kqc/cYYiuZMiN@" variabletype="">next</field>
                                          </block>
                                        </value>
                                      </block>
                                    </value>
                                    <next>
                                      <block type="bash_functions_arg" id="IVCNk,wm(k!(~/_cB-iZ">
                                        <field name="punctuation"> </field>
                                        <value name="data">
                                          <block type="bash_specvar" id="ZpEJ94LCO}tO[2B//LS-">
                                            <field name="NAME">@</field>
                                          </block>
                                        </value>
                                      </block>
                                    </next>
                                  </block>
                                </next>
                              </block>
                            </next>
                          </block>
                        </next>
                      </block>
                    </next>
                  </block>
                </next>
              </block>
            </next>
          </block>
        </next>
      </block>
    </statement>
    <value name="RETURN">
      <block type="math_number" id="{s9/BhV+%1ku5A=3!,q_">
        <field name="NUM">123</field>
      </block>
    </value>
  </block>
  <block type="bash_export" id="`IwFi-is*G+^P-7vw416" x="588" y="113">
    <value name="NAME">
      <block type="arbitrary_deconverter" id="jgpR{H9yIoe=,hBnWtxr">
        <statement name="NAME">
          <block type="variables_set" id="PZ94[|46-k1emmKxfB:F">
            <field name="VAR" id="/0,uM8CPLss/WG`)`!mI" variabletype="">item</field>
            <value name="VALUE">
              <block type="text" id="=zLYaD5NxjI(heiHm4(e">
                <field name="TEXT">x</field>
              </block>
            </value>
          </block>
        </statement>
      </block>
    </value>
    <next>
      <block type="arbitrary_converter" id=";%+|o!GAAH[ft4O]U(ed">
        <value name="content">
          <block type="arbitrary_deconverter" id="iMGm*xfgeol@F/_u9$VG">
            <statement name="NAME">
              <block type="arbitrary_converter" id="a!Z%Lww3r)AY:;DJ4#9{">
                <value name="content">
                  <block type="procedures_callreturn" id="1QTod~`*CE?IoUbv!$]D">
                    <mutation name="testFunction">
                      <arg name="test"></arg>
                      <arg name="next"></arg>
                    </mutation>
                    <value name="ARG0">
                      <block type="arbitrary_deconverter" id="b}]!^rB7[_[RR2^O=rcS">
                        <statement name="NAME">
                          <block type="text_print" id="lEaN$~;uHh#HzEfVxM*^">
                            <value name="TEXT">
                              <shadow type="text" id="G(mGQuD)RFclLkCNiRk?">
                                <field name="TEXT">abc</field>
                              </shadow>
                            </value>
                          </block>
                        </statement>
                      </block>
                    </value>
                    <value name="ARG1">
                      <block type="arbitrary_input" id="YtpmzDT?Nphg%`m}uSL|">
                        <field name="arbitraryInput">arbitraryInput</field>
                      </block>
                    </value>
                  </block>
                </value>
              </block>
            </statement>
          </block>
        </value>
        <next>
          <block type="arbitrary_code" id="o^)6oVc2lAG5dVS+3ten">
            <field name="arbitraryCode"></field>
            <next>
              <block type="arbitrary_code" id=":6+lSF6bl7dCVP9Bwo,1">
                <field name="arbitraryCode">true</field>
                <next>
                  <block type="arbitrary_code" id=";!2eKe5KH~L{=rOgGaGU">
                    <field name="arbitraryCode"></field>
                    <next>
                      <block type="bash_addlist" id="bdJ1*Df$7:|*;R/c=nr+">
                        <field name="variableName" id="/0,uM8CPLss/WG`)`!mI" variabletype="">item</field>
                        <value name="content">
                          <block type="text" id="Z.JL!,RNy*#MoD_P{b23">
                            <field name="TEXT">test1</field>
                          </block>
                        </value>
                        <next>
                          <block type="bash_addlist" id="Ws?*S!:]hv1lVgr#gR:@">
                            <field name="variableName" id="/0,uM8CPLss/WG`)`!mI" variabletype="">item</field>
                            <value name="content">
                              <block type="bash_doublequote" id="AM*gZtb^[8JQ#YT$/Q5k">
                                <value name="NAME">
                                  <block type="arbitrary_input" id="kLv.xy~9^Kz79rY(5ffh">
                                    <field name="arbitraryInput">test2</field>
                                  </block>
                                </value>
                              </block>
                            </value>
                            <next>
                              <block type="bash_addlist" id="W)r!0nu-tyE$x0.NTA3D">
                                <field name="variableName" id="/0,uM8CPLss/WG`)`!mI" variabletype="">item</field>
                                <value name="content">
                                  <block type="bash_singlequote" id="]-[xKc*8-7E_Dz/-!ZZM">
                                    <value name="NAME">
                                      <block type="arbitrary_input" id="8Ae`{LOaA8esy9#!Vo-+">
                                        <field name="arbitraryInput">test3</field>
                                      </block>
                                    </value>
                                  </block>
                                </value>
                                <next>
                                  <block type="controls_forEach" id="}AtGyE1jXLFe`Y|-,](d">
                                    <field name="VAR" id="_8m`2v87#x,S1Cosh{L%" variabletype="">i</field>
                                    <value name="LIST">
                                      <block type="bash_getlist" id="KPI(`#x}a_ICbfc;D/_y">
                                        <field name="variableName" id="/0,uM8CPLss/WG`)`!mI" variabletype="">item</field>
                                      </block>
                                    </value>
                                    <statement name="DO">
                                      <block type="text_print" id="oc,Q/=E-S-o!Pw4IrH?b">
                                        <value name="TEXT">
                                          <shadow type="text" id="a3}2r3_@l?}FM-I0ebq}">
                                            <field name="TEXT">abc</field>
                                          </shadow>
                                          <block type="bash_deref" id=":x[+z]j=.U2bT=1M/Xu#">
                                            <value name="source">
                                              <block type="variables_get" id="kSd]!s8z=h5am~J{^pU4">
                                                <field name="VAR" id="_8m`2v87#x,S1Cosh{L%" variabletype="">i</field>
                                              </block>
                                            </value>
                                          </block>
                                        </value>
                                        <next>
                                          <block type="text_print" id="(.aY8,VZ,QLg=0[$}s7]">
                                            <value name="TEXT">
                                              <shadow type="text" id="?OSS|w:ea+LdmRn=5ani">
                                                <field name="TEXT">abc</field>
                                              </shadow>
                                              <block type="bash_deref_unquoted" id="_[S@`r#r:%zjA/h_]v~#">
                                                <value name="source">
                                                  <block type="variables_get" id="|69h|A:1A{~m-zO|Haq:">
                                                    <field name="VAR" id="_8m`2v87#x,S1Cosh{L%" variabletype="">i</field>
                                                  </block>
                                                </value>
                                              </block>
                                            </value>
                                          </block>
                                        </next>
                                      </block>
                                    </statement>
                                    <next>
                                      <block type="arbitrary_converter" id="Qz~%Cck=;Q#N7M#I#QUm">
                                        <value name="content">
                                          <block type="arbitrary_deconverter" id="4+/39@Hn=ulhji,b#;4h">
                                            <statement name="NAME">
                                              <block type="text_print" id="u9s$z@6R`eo4B.R3fyz=">
                                                <value name="TEXT">
                                                  <shadow type="text" id="bS5Lyii`?4e{W`DBF3C+">
                                                    <field name="TEXT">abc</field>
                                                  </shadow>
                                                  <block type="bash_pipe" id="M,ml`tgj7kveOstBu2,M">
                                                    <value name="source">
                                                      <block type="bash_command_substitution" id="VA0wY[aIr=vDp8XS)Em[">
                                                        <value name="NAME">
                                                          <block type="bash_pipe" id="jN^oZJ+5sG:,lLuJ`h*d">
                                                            <value name="source">
                                                              <block type="arbitrary_deconverter" id="HhPkTuLZxlE(%bfYpXTF">
                                                                <statement name="NAME">
                                                                  <block type="text_print" id="~0sotUt$D_Z`@0;)Hor0">
                                                                    <value name="TEXT">
                                                                      <shadow type="text" id="4I4g{=SQMU_3t/B9sDWe">
                                                                        <field name="TEXT">test</field>
                                                                      </shadow>
                                                                    </value>
                                                                  </block>
                                                                </statement>
                                                              </block>
                                                            </value>
                                                            <value name="destination">
                                                              <block type="arbitrary_deconverter" id="eVd{2:3|)S)-/5yi}Sc#">
                                                                <statement name="NAME">
                                                                  <block type="arbitrary_code" id="%/Ea93zK#tZ(IzD0[[_i">
                                                                    <field name="arbitraryCode">cat</field>
                                                                  </block>
                                                                </statement>
                                                              </block>
                                                            </value>
                                                          </block>
                                                        </value>
                                                      </block>
                                                    </value>
                                                    <value name="destination">
                                                      <block type="arbitrary_input" id="K[zO!*MHBx@`cqRazNTO">
                                                        <field name="arbitraryInput">cat</field>
                                                      </block>
                                                    </value>
                                                  </block>
                                                </value>
                                              </block>
                                            </statement>
                                          </block>
                                        </value>
                                        <next>
                                          <block type="bash_case" id="!o`4dmBi.w+*)!^QHcyZ">
                                            <value name="caseData">
                                              <block type="math_number" id="|Yfpk)Cg.)i3ggkxK`dG">
                                                <field name="NUM">123</field>
                                              </block>
                                            </value>
                                            <statement name="caseActions">
                                              <block type="bash_in" id="zhhZEOtKG%q7a-P@5lv!">
                                                <field name="punctuation">;&amp;</field>
                                                <value name="inData">
                                                  <block type="math_number" id="XZAoVG_Tbp+DKBCb*2iO">
                                                    <field name="NUM">123</field>
                                                  </block>
                                                </value>
                                                <statement name="inActions">
                                                  <block type="text_print" id="{8?5(T)E+.Y[d1Q7.oki">
                                                    <value name="TEXT">
                                                      <shadow type="text" id="tLz!R+,xK(;Eql6hZ_7S">
                                                        <field name="TEXT">abc</field>
                                                      </shadow>
                                                    </value>
                                                  </block>
                                                </statement>
                                                <next>
                                                  <block type="bash_in" id="_:@O-r.?`{o6|V=1}9t|">
                                                    <field name="punctuation">;;</field>
                                                    <value name="inData">
                                                      <block type="arbitrary_input" id="p#}:Uc+4?lfE^Wp,86k2">
                                                        <field name="arbitraryInput">*</field>
                                                      </block>
                                                    </value>
                                                    <statement name="inActions">
                                                      <block type="text_print" id="Li|{8]Tc_PB78GYt+(ie">
                                                        <value name="TEXT">
                                                          <shadow type="text" id="h4n7LjoXCkox|*1P?E+4">
                                                            <field name="TEXT">xyz</field>
                                                          </shadow>
                                                        </value>
                                                      </block>
                                                    </statement>
                                                  </block>
                                                </next>
                                              </block>
                                            </statement>
                                          </block>
                                        </next>
                                      </block>
                                    </next>
                                  </block>
                                </next>
                              </block>
                            </next>
                          </block>
                        </next>
                      </block>
                    </next>
                  </block>
                </next>
              </block>
            </next>
          </block>
        </next>
      </block>
    </next>
  </block>
</xml>
