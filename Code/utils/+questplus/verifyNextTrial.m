function [houseEye, x, sch] = verifyNextTrial(vs, qp, sch)
% questplus.verifyNextTrial  Next trial of a verification block (questplus.verifyControl):
% eye configuration from the balanced block schedule (mixed trials are
% re-queued as usual), contrast ratio fixed at the estimate at block start.
[houseEye, sch] = questplus.schedule('next', sch);
x = vs.xVerify(find(qp.houseEyeValues == houseEye, 1));
end
