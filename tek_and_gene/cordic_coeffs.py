import math

for start_val in range(0, 2):
    a=range(start_val, 20)
    print("------------------------------------------------------------------------")
    print("Starting at " + str( start_val ))
    print("Assume the input has been divided by 2, display of the error after some posttreatement")
    print("------------------------------------------------------------------------")
    print("shifts\tarc tg\t\tangle\t\t\tnormalised 0..2.pi angle -> 0.00..1.00\t\t\tcumulative\terror if 1.0+\terror if 1.0+")
    if start_val == 0:
        title_c_p_h = "0.125+0.625\t0.125+0.625+0.015625+0.0078125"
    else:
        title_c_p_h = "0.5+0.125\t0.5+0.125+0.0625+0.015625"
    print("N\t/\t\tradians\t\t\t8 bits\t16 bits\t\t24 bits\t\t32 bits\t\t1/cosine\t"+title_c_p_h)
    cumul_cos = 1.0
    list_16 = []
    list_24 = []
    list_32 = []

    for ind in a:
        the_shift = 1 / float(2**ind)
        the_angle = math.atan(the_shift)
        cumul_cos *= math.cos(the_angle)
        the_angle_8 = (the_angle / (2 * math.pi)) * 2**8
        the_angle_16 = (the_angle / (2 * math.pi)) * 2**16
        the_angle_24 = (the_angle / (2 * math.pi)) * 2**24
        the_angle_32 = (the_angle / (2 * math.pi)) * 2**32
        list_16.append(round(the_angle_16))
        list_24.append(round(the_angle_24))
        list_32.append(round(the_angle_32))
        if start_val == 0:
            cumul_pseudo_hex   = "{:.12f}".format(2.0 * cumul_cos - 1.0 -0.125 - 0.0625)
            cumul_pseudo_hex_2 = "{:.12f}".format(2.0 * cumul_cos - 1.0 -0.125 - 0.0625 - 0.015625 - 0.0078125 )
        else:
            cumul_pseudo_hex   = "{:.12f}".format(2.0 * cumul_cos - 1.0 - 0.5 - 0.125)
            cumul_pseudo_hex_2 = "{:.12f}".format(2.0 * cumul_cos - 1.0 - 0.5 - 0.125 - 0.0625 - 0.015625)
        print(str(ind) + ":\t" + "{:.10f}".format(the_shift) + "\t" + str(the_angle) + "\t",end='')
        print("{:7.4f}".format(the_angle_8) + "\t" + "{:8.3f}".format(the_angle_16) + "\t",end='')
        print("{:10.2f}".format(the_angle_24) + "\t" + "{:11.1f}".format(the_angle_32) + "\t",end='')
        print("{:.12f}".format(1 / cumul_cos) + "\t" + cumul_pseudo_hex,end='')
        print("\t" + cumul_pseudo_hex_2)

    print("C plus plus list, ",end='')
    print("replace [] by {}")
    print(list_16)
    print(list_24)
    print(list_32)
    print("VHDL list")
    print(":= ( ", end="")
    for ind, val in enumerate(list_24):
        print ( 'x"' + "{:06X}".format(val) + '"',end="")
        if ind != len(list_24) - 1:
            print(', ',end="")
    print(" )")
