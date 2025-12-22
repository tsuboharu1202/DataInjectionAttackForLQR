A = rand(4,4);
B = rand(4,4);

[UA, SA, VA] = svd(A);
disp("UA");disp(UA);
disp("SA");disp(SA);
SA = [0.8,0,0,0;
    0,0.3,0,0;
    0,0,-0.5-1i*0.5,0;
    0,0,0,-0.5+1i*0.5];
A= A*SA*A^(-1);
disp("VA");disp(VA);
[UB, SB, VB] = svd(B);
disp("UB");disp(UB);
disp("SB");disp(SB);
disp("VB");disp(VB);

P = A*B;
[UP, SP, VP] = svd(P);
disp("UP");disp(UP);
disp("SP");disp(SP);
disp("VP");disp(VP);
cross_A = det(A);
cross_A = SA(1,1)*SA(2,2)*SA(3,3)*SA(4,4);
cross_B = SB(1,1)*SB(2,2)*SB(3,3);
disp(cross_A*cross_B);
cross_P = SP(1,1)*SP(2,2)*SP(3,3);
disp(cross_P);

disp("SA(1,1)*SB(1,1)");disp(SA(1,1)*SB(1,1));
disp("SP(1,1)");disp(SP(1,1));
disp("VA'*UB");disp(VA'*UB);
disp("tr(VA'*UB)");disp(trace((VA'*UB)));

sc = ones(1,4)*VA'*UB*ones(4,1);
disp("sc");disp(sc);

disp("A");disp(A);
[~, SA, ~] = svd(A);
disp("SA");disp(SA);
disp("eig");disp(eig(A));