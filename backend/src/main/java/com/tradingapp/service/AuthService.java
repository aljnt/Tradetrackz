package com.tradingapp.service;

import com.tradingapp.dto.AuthRequest;
import com.tradingapp.dto.AuthResponse;
import com.tradingapp.dto.RegisterRequest;
import com.tradingapp.model.User;
import com.tradingapp.repository.UserRepository;
import com.tradingapp.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim() : "";
        String username = request.getUsername() != null ? request.getUsername().trim() : "";

        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("Email is already taken");
        }
        if (userRepository.existsByUsername(username)) {
            throw new RuntimeException("Username is already taken");
        }

        var user = User.builder()
                .username(username)
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .build();
        
        userRepository.save(user);

        var jwtToken = jwtUtil.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .username(user.getActualUsername())
                .email(user.getEmail())
                .build();
    }

    public AuthResponse authenticate(AuthRequest request) {
        String identifier = request.getEmail() != null ? request.getEmail().trim() : "";
        
        var user = userRepository.findByEmail(identifier)
                .or(() -> userRepository.findByUsername(identifier))
                .orElseThrow(() -> new RuntimeException("Invalid email/username or password"));

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        user.getEmail(),
                        request.getPassword()
                )
        );
        
        var jwtToken = jwtUtil.generateToken(user);
        
        return AuthResponse.builder()
                .token(jwtToken)
                .username(user.getActualUsername())
                .email(user.getEmail())
                .build();
    }
}
