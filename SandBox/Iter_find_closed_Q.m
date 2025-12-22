function Q_opt = Iter_find_closed_Q(sd)
    [L_temp, ~, ~, ~] = solveSDPBySystem(sd);
    [UL,SL,~] = svd(L_temp);
    Q_temp = Closed_L_SDP(L_temp,sd);
    iter_max = 20;
    for iter = 1:iter_max
        disp(iter);disp(" : times");
        if (norm(L_temp - Q_temp,2) <= 1e-2)
            disp("success");
            break;
        end
        [UQ,~,VQ] = svd(Q_temp);
        L_next = UL*SL*VQ';
        if (norm(L_temp - L_next,2) <= 1e-2)
            disp("not success");
            break;
        end
        disp("norm");disp(norm(L_temp - Q_temp,2) );
        L_temp = L_next;
        Q_temp = Closed_L_SDP(L_temp,sd);
    end
    Q_opt = Q_temp;



        
