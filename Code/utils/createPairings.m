function table = createPairings(length)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creates pairings of each two values and returns it
% 
% Input:
%   length: the number of pairings
% 
% Output: a table containing the numbers from 1:length and random 
% permutation of it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    assert(mod(length,2) == 0, 'length must be even');
    perm = randperm(length);

    % Pair consecutive elements
    table = zeros(1, length);
    for i = 1:2:length
        a = perm(i);
        b = perm(i+1);
        table(a) = b;
        table(b) = a;
    end
end