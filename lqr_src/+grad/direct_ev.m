function [gradX_pi, gradZ_pi, gradU_pi] = direct_ev(sd)

    h = cfg.Const.FD_STEP;

    % ---- 基準の支配固有値 λ0（複素） ----
    lambda0 = dom_eig(sd);

    % -------- X の Πλ 勾配 --------
    if isempty(sd.X)
        gradX_pi = [];
    else
        gradX_pi = zeros(size(sd.X));
        for k = 1:numel(sd.X)
            Xp = sd.X; Xp(k) = Xp(k) + h;
            Xm = sd.X; Xm(k) = Xm(k) - h;
            gp = dom_eig(sd.withX(Xp));
            gm = dom_eig(sd.withX(Xm));
            g  = (gp - gm)/(2*h);                         % g: dλ/dX_k  (complex)
            gradX_pi(k) = real(lambda0)*real(g) + imag(lambda0)*imag(g); % Πλ(g)
        end
    end

    % -------- Z の Πλ 勾配 --------
    if isempty(sd.Z)
        gradZ_pi = [];
    else
        gradZ_pi = zeros(size(sd.Z));
        for k = 1:numel(sd.Z)
            Zp = sd.Z; Zp(k) = Zp(k) + h;
            Zm = sd.Z; Zm(k) = Zm(k) - h;
            gp = dom_eig(sd.withZ(Zp));
            gm = dom_eig(sd.withZ(Zm));
            g  = (gp - gm)/(2*h);
            gradZ_pi(k) = real(lambda0)*real(g) + imag(lambda0)*imag(g);
        end
    end

    % -------- U の Πλ 勾配 --------
    if isempty(sd.U)
        gradU_pi = [];
    else
        gradU_pi = zeros(size(sd.U));
        for k = 1:numel(sd.U)
            Up = sd.U; Up(k) = Up(k) + h;
            Um = sd.U; Um(k) = Um(k) - h;
            gp = dom_eig(sd.withU(Up));
            gm = dom_eig(sd.withU(Um));
            g  = (gp - gm)/(2*h);
            gradU_pi(k) = real(lambda0)*real(g) + imag(lambda0)*imag(g);
        end
    end

    % ===== ローカル関数 =====
    function lam = dom_eig(sysd)
        % SDP → K → 支配固有値 λ（絶対値最大のもの）
        [L,~,~,~] = sysd.solveSDPBySystem();
        [K,~] = sdp.postprocess_K(sysd.U, L, sysd.X);
        ev = eig(sysd.A + sysd.B*K);
        [~,ix] = max(abs(ev));
        lam = ev(ix);                 % 複素の場合あり
    end

    function B = add(A, D)
        if isempty(A), B = A; else, B = A + D; end
    end
end
