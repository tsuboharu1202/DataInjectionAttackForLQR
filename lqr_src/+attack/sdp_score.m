function [X_adv, Z_adv, U_adv] = sdp_score(sd)
    
    [dX, dZ, dU] = sdp_attack.calc_sdp(sd);
    X_adv = sd.X + dX;
    Z_adv = sd.Z + dZ;
    U_adv = sd.U + dU;
end
