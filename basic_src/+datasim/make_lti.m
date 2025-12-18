function [A,B,Q,R] = make_lti(n,m)

    A = rand(n,n);
    % A = (A-ones(n,n)*0.5)*2;
    B = rand(n,m);
    % B = (B - ones(n,m)*0.5)*2;


    Q = eye(n);
    R = eye(m)*0.1;

end
