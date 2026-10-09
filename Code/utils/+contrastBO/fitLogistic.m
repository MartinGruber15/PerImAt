function [params, paramCov] = fitLogistic(designMatrix, outcome, priorMean, priorSD)
% fitLogistic  Bayesian logistic regression, Laplace approximation.
%
%   P(outcome = 1) = 1 / (1 + exp(-designMatrix * params)),
%   params ~ N(priorMean, diag(priorSD^2))
%
% Returns the most probable parameters (MAP, found with damped Newton steps)
% and the covariance of the Gaussian that approximates the posterior around
% it.  With no data the result is simply the prior.  The prior also keeps the
% solution finite when the data are (almost) perfectly separable, which
% happens easily early in the run.

priorMean = priorMean(:);
outcome = outcome(:);
priorPrecision = 1 ./ priorSD(:).^2;
params = priorMean;
logPost = logPosterior(params, designMatrix, outcome, priorMean, priorPrecision);

for it = 1:100
    logit = designMatrix * params;
    p = 1 ./ (1 + exp(-logit));
    grad = designMatrix' * (outcome - p) - priorPrecision .* (params - priorMean);
    negHessian = designMatrix' * bsxfun(@times, designMatrix, p .* (1 - p)) + diag(priorPrecision);
    step = negHessian \ grad;

    % backtracking line search: halve the step until the posterior improves
    stepSize = 1;
    while stepSize > 1e-6
        paramsNew = params + stepSize * step;
        logPostNew = logPosterior(paramsNew, designMatrix, outcome, priorMean, priorPrecision);
        if logPostNew >= logPost, break; end
        stepSize = stepSize / 2;
    end
    if logPostNew < logPost, break; end      % no improvement possible: converged
    params = paramsNew;  logPost = logPostNew;
    if max(abs(stepSize * step)) < 1e-8, break; end
end

% posterior precision at the solution
p = 1 ./ (1 + exp(-(designMatrix * params)));
negHessian = designMatrix' * bsxfun(@times, designMatrix, p .* (1 - p)) + diag(priorPrecision);
paramCov = inv(negHessian);
paramCov = (paramCov + paramCov') / 2;
end


function logPost = logPosterior(params, designMatrix, outcome, priorMean, priorPrecision)
logit = designMatrix * params;
% sum( outcome*logit - log(1+exp(logit)) ), numerically stable
logLik = sum(outcome .* logit - (max(logit, 0) + log1p(exp(-abs(logit)))));
logPost = logLik - 0.5 * sum(priorPrecision .* (params - priorMean).^2);
end
