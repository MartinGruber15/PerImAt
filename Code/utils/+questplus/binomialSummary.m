function s = binomialSummary(k, n)
% questplus.binomialSummary  Proportion, Wilson 95% CI and exact two-sided
% binomial test against 0.5 (no Statistics Toolbox needed).
%
%   s = questplus.binomialSummary(k, n)   ->  s.p, s.ci95, s.pValue, s.k, s.n

s.k = k; s.n = n;
if n == 0
    s.p = NaN; s.ci95 = [NaN NaN]; s.pValue = NaN; return
end
s.p = k / n;
z = 1.959963984540054;
den = 1 + z^2 / n;
centre = (s.p + z^2 / (2 * n)) / den;
half = z * sqrt(s.p * (1 - s.p) / n + z^2 / (4 * n^2)) / den;
s.ci95 = [max(0, centre - half), min(1, centre + half)];
% exact two-sided test vs 0.5 (symmetric null -> double the smaller tail)
i = 0:n;
logpmf = gammaln(n + 1) - gammaln(i + 1) - gammaln(n - i + 1) + n * log(0.5);
pmf = exp(logpmf);
s.pValue = min(1, 2 * min(sum(pmf(i <= k)), sum(pmf(i >= k))));
end
