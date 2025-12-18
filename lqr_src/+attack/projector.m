function [dX,dZ,dU,checkX,checkZ,checkU] = projector(dX,dZ,dU,checkX,checkZ,checkU)
    epsilon = cfg.Const.ATTACKER_UPPERLIMIT;
    % X
    if ~isempty(dX)
        mX = ~checkX & (abs(dX) > cfg.Const.ATTACKER_UPPERLIMIT);    % まだ未処理 かつ |d|>ε
        dX(mX)     = epsilon .* sign(dX(mX));  % ε·sign に張り付け
        checkX(mX) = true;                     % 処理済みにする
    end
    % Z
    if ~isempty(dZ)
        mZ = ~checkZ & (abs(dZ) > cfg.Const.ATTACKER_UPPERLIMIT);
        dZ(mZ)     = epsilon .* sign(dZ(mZ));
        checkZ(mZ) = true;
    end
    % U
    if ~isempty(dU)
        mU = ~checkU & (abs(dU) > cfg.Const.ATTACKER_UPPERLIMIT);
        dU(mU)     = epsilon .* sign(dU(mU));
        checkU(mU) = true;
    end
end
