transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Jinhai\ Steakhouse/OneDrive/Misc.\ Projects/Niu32-multicycle {C:/Users/Jinhai Steakhouse/OneDrive/Misc. Projects/Niu32-multicycle/Niu32_multicycle.v}
vlog -vlog01compat -work work +incdir+C:/Users/Jinhai\ Steakhouse/OneDrive/Misc.\ Projects/Niu32-multicycle {C:/Users/Jinhai Steakhouse/OneDrive/Misc. Projects/Niu32-multicycle/SevenSeg.v}
vlog -vlog01compat -work work +incdir+C:/Users/Jinhai\ Steakhouse/OneDrive/Misc.\ Projects/Niu32-multicycle {C:/Users/Jinhai Steakhouse/OneDrive/Misc. Projects/Niu32-multicycle/SXT.v}

