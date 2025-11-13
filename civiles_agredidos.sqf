/*
    Script: Civiles Reactivos
    Descripción: Los civiles se arman y atacan cuando son agredidos
    Uso: Ejecutar en init.sqf o en el init de cada civil
*/

// Función para armar civiles
fn_armarCivil = {
    params ["_civil"];
    
    // Array de armas disponibles para civiles
    _armasDisponibles = [
        "hgun_Pistol_heavy_02_F",
        "hgun_ACPC2_F",
        "hgun_Rook40_F",
        "SMG_02_F",
        "hgun_PDW2000_F"
    ];
    
    // Seleccionar arma aleatoria
    _arma = selectRandom _armasDisponibles;
    
    // Remover arma actual y darle nueva arma
    removeAllWeapons _civil;
    _civil addMagazine [getArray (configFile >> "CfgWeapons" >> _arma >> "magazines") select 0, 4];
    _civil addWeapon _arma;
    
    // Cambiar a lado enemigo
    [_civil] joinSilent grpNull;
    _grupoHostil = createGroup east;
    [_civil] joinSilent _grupoHostil;
    
    // Hacer que el civil sea agresivo
    _civil setBehaviour "COMBAT";
    _civil setCombatMode "RED";
    
    // Mensaje de sistema
    systemChat format ["%1 se ha armado y es hostil!", name _civil];
};

// Función principal para monitorear civiles
fn_monitoreoCiviles = {
    params ["_civil"];
    
    _civil addEventHandler ["Hit", {
        params ["_unit", "_causante"];
        
        // Verificar que el causante es el jugador o su grupo
        if (isPlayer _causante || {_causante in units group player}) then {
            // Armar al civil
            [_unit] call fn_armarCivil;
            
            // Buscar civiles cercanos y armarlos también
            _civilesCercanos = nearestObjects [_unit, ["Civilian"], 50];
            {
                if (alive _x && _x != _unit && side _x == civilian) then {
                    [_x] call fn_armarCivil;
                };
            } forEach _civilesCercanos;
        };
    }];
    
    _civil addEventHandler ["Killed", {
        params ["_unit", "_asesino"];
        
        // Si matan a un civil, armar a los cercanos
        if (isPlayer _asesino || {_asesino in units group player}) then {
            _civilesCercanos = nearestObjects [_unit, ["Civilian"], 100];
            {
                if (alive _x && side _x == civilian) then {
                    [_x] call fn_armarCivil;
                };
            } forEach _civilesCercanos;
            
            // Mensaje de advertencia
            titleText ["¡Los civiles se están armando contra ti!", "PLAIN DOWN"];
        };
    }];
};

// APLICAR A TODOS LOS CIVILES EN EL MAPA
{
    if (side _x == civilian) then {
        [_x] call fn_monitoreoCiviles;
    };
} forEach allUnits;

// Monitorear nuevos civiles que aparezcan
addMissionEventHandler ["EntityCreated", {
    params ["_entidad"];
    
    if (_entidad isKindOf "CAManBase" && side _entidad == civilian) then {
        [_entidad] call fn_monitoreoCiviles;
    };
}];

hint "Sistema de civiles reactivos activado";

