<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inscripción Torneo Tekken 8</title>
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Google Fonts: Orbitron -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&display=swap" rel="stylesheet">
    
    <!-- Custom Styles -->
    <style>
        body {
            font-family: 'Orbitron', sans-serif;
            background-color: #111827; /* bg-gray-900 */
            background-image: 
                radial-gradient(circle at 1px 1px, rgba(255,255,255,0.1) 1px, transparent 0),
                radial-gradient(circle at 10px 10px, rgba(255,255,255,0.05) 1px, transparent 0);
            background-size: 20px 20px;
        }
        .text-glow {
            text-shadow: 0 0 8px rgba(236, 72, 153, 0.7), 0 0 20px rgba(219, 39, 119, 0.5);
        }
        .card {
            background-color: rgba(31, 41, 55, 0.8); /* bg-gray-800 with opacity */
            backdrop-filter: blur(10px);
            border: 1px solid rgba(75, 85, 99, 0.5);
        }
        .btn-primary {
            background: linear-gradient(45deg, #d946ef, #ec4899);
            transition: all 0.3s ease;
            box-shadow: 0 0 15px rgba(236, 72, 153, 0.5);
        }
        .btn-primary:hover {
            transform: scale(1.05);
            box-shadow: 0 0 25px rgba(236, 72, 153, 0.8);
        }
        .form-input {
            background-color: #374151; /* bg-gray-700 */
            border: 1px solid #4b5563; /* border-gray-600 */
            transition: all 0.3s ease;
        }
        .form-input:focus {
            outline: none;
            border-color: #ec4899;
            box-shadow: 0 0 10px rgba(236, 72, 153, 0.5);
        }
    </style>
</head>
<body class="text-white">

    <div class="container mx-auto p-4 md:p-8">
        
        <!-- Header -->
        <header class="text-center mb-8 md:mb-12">
            <h1 class="text-4xl md:text-6xl font-black uppercase text-glow tracking-wider">Torneo Tekken 8</h1>
            <p class="text-lg md:text-xl text-gray-400 mt-2">The King of Iron Fist Tournament</p>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-5 gap-8">
            
            <!-- Registration Form -->
            <main class="lg:col-span-2">
                <div class="card p-6 md:p-8 rounded-2xl">
                    <h2 class="text-2xl md:text-3xl font-bold mb-6 border-b-2 border-pink-500 pb-3">Formulario de Inscripción</h2>
                    <form id="registration-form">
                        <div class="space-y-6">
                            <div>
                                <label for="gamertag" class="block text-sm font-medium text-gray-300 mb-2">Gamertag / Nickname</label>
                                <input type="text" id="gamertag" name="gamertag" required class="form-input w-full p-3 rounded-lg" placeholder="Tu nombre de jugador">
                            </div>
                            <div>
                                <label for="email" class="block text-sm font-medium text-gray-300 mb-2">Correo Electrónico</label>
                                <input type="email" id="email" name="email" required class="form-input w-full p-3 rounded-lg" placeholder="tu@email.com">
                            </div>
                            <div>
                                <label for="mainCharacter" class="block text-sm font-medium text-gray-300 mb-2">Personaje Principal</label>
                                <input type="text" id="mainCharacter" name="mainCharacter" required class="form-input w-full p-3 rounded-lg" placeholder="Ej: Jin Kazama, Kazuya, Reina">
                            </div>
                            <div>
                                <button type="submit" id="submit-button" class="btn-primary w-full font-bold py-3 px-4 rounded-lg uppercase tracking-wider">
                                    Inscribirse
                                </button>
                            </div>
                        </div>
                    </form>
                    <div id="success-message" class="hidden mt-4 text-center p-3 rounded-lg bg-green-500/20 text-green-300 border border-green-500">
                        ¡Inscripción exitosa!
                    </div>
                </div>
            </main>

            <!-- Registered Players List -->
            <aside class="lg:col-span-3">
                 <div class="card p-6 md:p-8 rounded-2xl h-full">
                    <h2 class="text-2xl md:text-3xl font-bold mb-6 border-b-2 border-fuchsia-500 pb-3">Luchadores Inscritos</h2>
                    <div id="loading-indicator" class="text-center text-gray-400">Cargando jugadores...</div>
                    <div id="players-list" class="space-y-4 max-h-[600px] overflow-y-auto pr-2">
                        <!-- Player items will be injected here by JavaScript -->
                    </div>
                </div>
            </aside>
        </div>
        
        <!-- Footer -->
        <footer class="text-center mt-12 text-gray-500">
            <p>Tekken 8 y todos los personajes son propiedad de Bandai Namco Entertainment.</p>
            <p>Página de inscripción creada con fines demostrativos.</p>
        </footer>
    </div>

    <!-- Firebase SDK -->
    <script type="module">
        // Importa las funciones necesarias del SDK de Firebase
        import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
        import { getAuth, signInAnonymously, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
        import { getFirestore, collection, addDoc, onSnapshot, serverTimestamp, query } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

        // --- Configuración de Firebase ---
        // La configuración de Firebase se inyectará aquí automáticamente en el entorno de ejecución.
        // No es necesario que la modifiques.
        const firebaseConfig = JSON.parse(typeof __firebase_config !== 'undefined' ? __firebase_config : '{}');
        const appId = typeof __app_id !== 'undefined' ? __app_id : 'tekken8-tournament';

        // --- Inicialización de Firebase ---
        let app, auth, db;
        try {
            app = initializeApp(firebaseConfig);
            auth = getAuth(app);
            db = getFirestore(app);
        } catch (e) {
            console.error("Error al inicializar Firebase:", e);
            document.getElementById('loading-indicator').innerText = "Error al conectar con la base de datos.";
            return;
        }

        // --- Autenticación y Carga de Datos ---
        onAuthStateChanged(auth, user => {
            if (user) {
                // El usuario está autenticado (anónimamente), ahora podemos cargar los datos.
                loadRegisteredPlayers();
            } else {
                // Si no hay usuario, intenta iniciar sesión anónimamente.
                signInAnonymously(auth).catch(error => {
                    console.error("Error en el inicio de sesión anónimo:", error);
                    document.getElementById('loading-indicator').innerText = "Error de autenticación.";
                });
            }
        });

        const playersCollectionPath = `/artifacts/${appId}/public/data/players`;

        // --- Lógica para Cargar Jugadores ---
        function loadRegisteredPlayers() {
            const playersList = document.getElementById('players-list');
            const loadingIndicator = document.getElementById('loading-indicator');
            const q = query(collection(db, playersCollectionPath));

            onSnapshot(q, (snapshot) => {
                loadingIndicator.classList.add('hidden');
                playersList.innerHTML = ''; // Limpia la lista antes de volver a renderizar
                
                if (snapshot.empty) {
                    playersList.innerHTML = '<p class="text-gray-400 text-center">Aún no hay nadie inscrito. ¡Sé el primero!</p>';
                    return;
                }

                snapshot.docs.forEach(doc => {
                    const player = doc.data();
                    const playerElement = document.createElement('div');
                    playerElement.className = 'flex items-center justify-between p-4 rounded-lg bg-gray-700/50 hover:bg-gray-700 transition-colors duration-300';
                    playerElement.innerHTML = `
                        <div>
                            <p class="font-bold text-lg text-fuchsia-400">${player.gamertag}</p>
                            <p class="text-sm text-gray-400">Main: ${player.mainCharacter}</p>
                        </div>
                        <div class="text-xs text-gray-500">
                            ${player.timestamp ? new Date(player.timestamp.seconds * 1000).toLocaleString() : 'Ahora'}
                        </div>
                    `;
                    playersList.appendChild(playerElement);
                });
            }, (error) => {
                console.error("Error al obtener los jugadores: ", error);
                loadingIndicator.innerText = "No se pudieron cargar los jugadores.";
            });
        }

        // --- Lógica del Formulario ---
        const form = document.getElementById('registration-form');
        const submitButton = document.getElementById('submit-button');
        const successMessage = document.getElementById('success-message');

        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            if (!auth.currentUser) {
                alert("Aún no estás conectado. Por favor, espera un momento y vuelve a intentarlo.");
                return;
            }

            submitButton.disabled = true;
            submitButton.innerText = 'INSCRIBIENDO...';

            const gamertag = form.gamertag.value;
            const email = form.email.value;
            const mainCharacter = form.mainCharacter.value;

            try {
                // Añade un nuevo documento a la colección de jugadores
                await addDoc(collection(db, playersCollectionPath), {
                    gamertag: gamertag,
                    email: email,
                    mainCharacter: mainCharacter,
                    timestamp: serverTimestamp()
                });

                // Muestra mensaje de éxito y resetea el formulario
                successMessage.classList.remove('hidden');
                form.reset();
                setTimeout(() => {
                    successMessage.classList.add('hidden');
                }, 3000);

            } catch (error) {
                console.error("Error al añadir el documento: ", error);
                alert("Hubo un error al registrar tu inscripción. Inténtalo de nuevo.");
            } finally {
                submitButton.disabled = false;
                submitButton.innerText = 'Inscribirse';
            }
