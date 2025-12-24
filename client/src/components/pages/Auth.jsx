import React, { useState } from "react";
import "./css/Auth.css";
import { useLogin } from "../../hooks/users";
import { useNavigate, useLocation } from "react-router-dom";
import { decodeToken } from "../../utils/jwt";

export default function Auth() {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState(null);
    const login = useLogin();
    const navigate = useNavigate();
    const location = useLocation();
    const from = location.state?.from?.pathname || '/cabinet';

    const onSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        try {
            const res = await login.mutateAsync({ username, password });
            // Optionally read user info from token
            const user = res.accessToken ? decodeToken(res.accessToken) : null;
            navigate(from, { replace: true });
        } catch (err) {
            setError(err.message || 'Auth failed');
        }
    }

    return (
        <main className="auth">
            <div className="auth__header">
                <h1>Авторизація</h1>
                <form className="auth__content" onSubmit={onSubmit}>
                    <label htmlFor="username">Ім'я користувача чи електронна пошта:</label>
                    <input value={username} onChange={e => setUsername(e.target.value)} type="text" id="username" name="username" required />
                    <label htmlFor="password">Пароль:</label>
                    <input value={password} onChange={e => setPassword(e.target.value)} type="password" id="password" name="password" required />
                    <br />
                    <button type="submit" disabled={login.isLoading}>Увійти</button>
                    {error && <div className="error">{error}</div>}
                </form>
            </div>
        </main>
    );
}