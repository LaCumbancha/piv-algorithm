function correlation = correlate(A, B, N)
    A = single(A); B = single(B);
    fftA = fft2(A); fftB = fft2(B);
    correlation = fftshift(fftshift(real(ifft(ifft(conj(fftA) .* fftB, N, 2), N, 1)), 2), 1);
    correlation(correlation < 0) = 0;
end
