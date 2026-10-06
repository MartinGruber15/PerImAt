function [theta, Sigma] = fitLogistic(Phi, y, priorMean, priorSD)
% fitLogistic  Bayesian logistic regression, Laplace approximation.
%
%   P(y=1) = 1 / (1 + exp(-Phi*theta)),   theta ~ N(priorMean, diag(priorSD^2))
%
% Returns the most probable parameters (MAP, found with damped Newton steps)
% and the covariance of the Gaussian that approximates the posterior around
% it.  With no data the result is simply the prior.  The prior also keeps the
% solution finite when the data are (almost) perfectly separable, which
% happens easily early in the run.

priorMean = priorMean(:);
y = y(:);
P = 1 ./ priorSD(:).^2;                  % prior precisions
theta = priorMean;
f = logPosterior(theta, Phi, y, priorMean, P);

for it = 1:100
    eta = Phi * theta;
    p = 1 ./ (1 + exp(-eta));
    grad = Phi' * (y - p) - P .* (theta - priorMean);
    H = Phi' * bsxfun(@times, Phi, p .* (1 - p)) + diag(P);   % negative Hessian
    step = H \ grad;

    % backtracking line search: halve the step until the posterior improves
    t = 1;
    while t > 1e-6
        thetaNew = theta + t * step;
        fNew = logPosterior(thetaNew, Phi, y, priorMean, P);
        if fNew >= f, break; end
        t = t / 2;
    end
    if fNew < f, break; end              % no improvement possible: converged
    theta = thetaNew;  f = fNew;
    if max(abs(t * step)) < 1e-8, break; end
end

% precision at the solution
p = 1 ./ (1 + exp(-(Phi * theta)));
H = Phi' * bsxfun(@times, Phi, p .* (1 - p)) + diag(P);
Sigma = inv(H);
Sigma = (Sigma + Sigma') / 2;
end


function f = logPosterior(theta, Phi, y, priorMean, P)
eta = Phi * theta;
% sum( y*eta - log(1+exp(eta)) ), numerically stable
logLik = sum(y .* eta - (max(eta, 0) + log1p(exp(-abs(eta)))));
f = logLik - 0.5 * sum(P .* (theta - priorMean).^2);
end
