--20171122
for select(�C��B�Z�O�A���x�u������(���x�귽))
    for select(�C��B���~�B���~�u������(�զX���x�����]����))
        select ���~�O���O�զX���x
        select ���x�O�_�i�H�Ͳ��Ӳ��~
        select ���x�Ѿl�i�ήɶ�
        select ���~�Ѿl���Ƥ�����
        if  ���x�O�_�٦��Ѿl�ɶ��i�H�w��
            if  ���~�٦��Ѿl�ɶ��n�� (l_unprod_min <= 0)
                continue
            else:
                if  ���x�O�_�i�H�Ͳ��Ӳ��~(mach_ava_prod           > 0)
                    if ��D�զX���x �άO �D�զX���x���~ (R_AVA_MACH.groupable IS NULL OR G_main_ava_item = 0)
                        if  �s�@�Ӯ� < ���x�i�� (l_unprod_min < ava_minute THEN)
                            UPDATE Mes_Mach_Daily_T 
                                Work_Minute                          = ava_minute - l_unprod_min --(���x�i�� = ���x�i�� - �s�y�ӥ�)
                            INSERT  INTO mes_plan_mach_wk_t 
                                use_work_minute = l_unprod_min --���x�ӥήɶ� = �s�@�Ӯ�
                                PLAN_QTY        = l_unprod_qty --���~�Ͳ��ƶq
                        else:  �s�@�Ӯ� > ���x�i�� 
                            select �ξ��x�i�Υh�p��s�y�ƶq into l_unprod_qty
                            UPDATE Mes_Mach_Daily_T
                                 Work_Minute                          = 0 --�i�ήɶ����Y
                            INSERT  INTO mes_plan_mach_wk_t 
                                use_work_minute = ava_minute    --���x�i��
                                plan_qty        = l_unprod_qty  --���~�Ͳ��ƶq
                        end if
                    else --�զX���x
                        
                        for select mes_mach_group_b_t ��X�P�ժ������A�̤p�i��
                            select �γ̤p�i�Υh�p��Ͳ��ƶq into l_unprod_qty
                            if g_mach.ava_mach_min = 0 �w�g���@�x�S���i�ήɶ��F�A�������
                                break;
                            else �i�H��
                                if l_unprod_min /2                 > g_mach.min_work_minute THEN --(�s�@�Ӯ�)/2 > �̤p�i��
                                    UPDATE Mes_Mach_Daily_T
                                        Work_Minute = g_mach.ava_mach_min
                                    INSERT INTO mes_plan_mach_wk_t
                                        use_work_minute     =   g_mach.min_work_minute --�̤p�i��
                                        plan_qty            =   ceil(l_unprod_qty)  --
                                else    --(�s�@�Ӯ�)/2 < �̤p�i��
                                    select ���٥��s�y�������ƥh�� �٥��s�y���ƶq
                                    UPDATE  mes_mach_daily_t
                                        work_minute                          = ceil(g_mach.min_work_minute - (l_unprod_min/2)) --�̤p�i�� - ������/2
                                    INSERT INTO 
                                        use_work_minute =   ceil(l_unprod_min/2)
                                        plan_qty    =   ceil(l_unprod_qty/2) )
                                end if;
                        end loop; 
                    end if    
                else:
                    end if;
            end if;
        else �D�զX���x
        end if;
end loop;
