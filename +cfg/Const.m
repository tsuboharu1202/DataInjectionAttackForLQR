classdef Const
    properties (Constant)
        %　全体jのステップ数
        SAMPLE_COUNT =10
        
        % 数値微分の既定ステップ（相対スケール）
        FD_STEP = eps^(1/3)
        % FD_USE_CENTER boolean = true
        
        % SDP の既定
        GAMMA = 1e-4
        SOLVER = "mosek"
        VERBOSE = 0
        
        % 攻撃側制約
        ATTACKER_UPPERLIMIT = 0.01
        IDGSM_ALPHA = 0.001
        MAX_ITERATION = 10
        
        % 乱数生成
        SEED = []
    end
end
