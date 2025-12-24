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
        ATTACKER_UPPERLIMIT = 1e-3
        IDGSM_ALPHA = 5*1e-5
        MAX_ITERATION = 100
        
        % 局所最適解回避（IDGSM用）
        IDGSM_ESCAPE_LOCAL_MIN = true  % 局所最適解を回避するかどうか
        IDGSM_RHO_CHANGE_THRESHOLD = 1e-4  % スペクトル半径の変化がこの値以下だったらランダムノイズを加える
        IDGSM_RANDOM_NOISE_SCALE = 5  % ランダムノイズのスケール（ATTACKER_UPPERLIMITに対する相対値）
        IDGSM_STAGNATION_STEPS = 10  % このステップ数連続で変化が閾値以下だったらランダムノイズを加える
        
        % 乱数生成
        SEED = []
    end
end
