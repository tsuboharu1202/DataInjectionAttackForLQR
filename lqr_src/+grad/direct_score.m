function [gradX, gradZ, gradU] = direct_score(sd, h)
    if nargin<2 || isempty(h), h = cfg.Const.FD_STEP; end

    % ---- X ----
    if isempty(sd.X)
        gradX = [];
    else
        gradX = zeros(size(sd.X));
        for k = 1:numel(sd.X)
            Xp = sd.X; Xm = sd.X;
            step = h*max(1,abs(Xp(k)));           % 相対ステップ（数値安定）
            Xp(k) = Xp(k) + step; Xm(k) = Xm(k) - step;
            gp = calc_score(sd.withX(Xp));
            gm = calc_score(sd.withX(Xm));
            gradX(k) = (gp - gm) / (2*step);      % ★ 要素代入！
        end
    end

    % ---- Z ----
    if isempty(sd.Z)
        gradZ = [];
    else
        gradZ = zeros(size(sd.Z));
        for k = 1:numel(sd.Z)
            Zp = sd.Z; Zm = sd.Z;
            step = h*max(1,abs(Zp(k)));
            Zp(k) = Zp(k) + step; Zm(k) = Zm(k) - step;
            gp = calc_score(sd.withZ(Zp));
            gm = calc_score(sd.withZ(Zm));
            gradZ(k) = (gp - gm) / (2*step);
        end
    end

    % ---- U ----
    if isempty(sd.U)
        gradU = [];
    else
        gradU = zeros(size(sd.U));
        for k = 1:numel(sd.U)
            Up = sd.U; Um = sd.U;
            step = h*max(1,abs(Up(k)));
            Up(k) = Up(k) + step; Um(k) = Um(k) - step;
            gp = calc_score(sd.withU(Up));
            gm = calc_score(sd.withU(Um));
            gradU(k) = (gp - gm) / (2*step);
        end
    end

    function J = calc_score(sd1)
        % SDP -> J_opt（論文の目的関数側を返す想定）
        K = sd1.opt_K();
        J = utils.real_score(sd1, K);
    end
end
