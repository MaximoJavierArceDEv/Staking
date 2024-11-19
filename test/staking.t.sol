// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/console.sol";
import "forge-std/Test.sol"; // Importa la librería de pruebas de Foundry
import {Staking} from "../src/staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // Importa ERC20 para crear un token de prueba

contract TestToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Función para emitir tokens para una dirección
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract StakingTest is Test {
    Staking public staking;
    TestToken token;

    address user = address(0x123);

    // Función para configurar el entorno de la prueba
    function setUp() public {
        // Desplegar un token ERC20 de prueba
        token = new TestToken("TestToken", "TT");

        // Desplegar el contrato de Staking pasando el contrato token directamente
        staking = new Staking(token);

        // Emitir tokens para el usuario
        token.mint(user, 1000 * 10 ** 18);

        // Emitir tokens para el propietario
        token.mint(staking.owner(), 1000 * 10 ** 18);
    }

    // Verificar que el contrato de staking se ha desplegado correctamente
    function testDeploy() public view {
        assert(address(staking) != address(0));
    }

    // Verificar si el staking funciona correctamente
    function testStake() public {
        uint256 amount = 500 * 10 ** 18; // Establecemos la cantidad de tokens a stakear

        // Aprobar el contrato de staking para transferir los tokens
        vm.startPrank(user);
        token.approve(address(staking), amount); // Aprobar los tokens para staking
        vm.stopPrank();

        // Realizar el staking de tokens
        vm.startPrank(user);
        staking.stake(amount, 1); // Realizar staking de 500 tokens por 1 año
        vm.stopPrank();
    }

    // Función para retirar los tokens del staking
    function unstake() public {
        vm.prank(user);
        staking.unStake();
    }

    // Verificar que el usuario pueda reclamar la recompensa después de un año
    function testclaimReward() public {
        uint256 amount = 500 * 10 ** 18; // Establecemos la cantidad de tokens a stakear

        // Aprobar el contrato de staking para mover los tokens del usuario
        vm.prank(user);
        token.approve(address(staking), amount);

        // Realizar el staking
        vm.prank(user);
        staking.stake(amount, 1); // 1 año

        // Simular que ha pasado un año
        uint256 startTime = block.timestamp;
        vm.warp(startTime + 365 days); // Avanza el tiempo 1 año desde el 'startTime'

        // Reclamar la recompensa
        vm.prank(user);
        staking.claimReward();

        // Verificar el saldo después de reclamar la recompensa
        uint256 balance = token.balanceOf(user);
        console.log(
            "Nuevo balance del usuario despues de claimReward:",
            balance
        );
    }

    // Verificar que el propietario puede depositar tokens en el contrato de staking
    function testOwnerDeposit() public {
        address contractOwner = staking.owner(); // Obtén el propietario del contrato
        uint256 depositAmount = 1000 * 10 ** 18; // Establecemos la cantidad de tokens a depositar

        // Aprobar el contrato de staking para transferir los tokens del propietario
        vm.prank(contractOwner);
        token.approve(address(staking), depositAmount); // Aprobar los tokens para staking

        // Realizar el depósito de tokens
        vm.prank(contractOwner);
        staking.ownerDeposit(depositAmount);

        // Verificar el balance del contrato de staking
        uint256 contractBalance = token.balanceOf(address(staking));
        assertEq(contractBalance, depositAmount); // Asegúrate de que el saldo del contrato es el correcto
    }

    // Verificar el cálculo de la recompensa después de un año de staking
    function testCalculateReward() public {
        uint256 stakingAmount = 100 * 10 ** 18; // Establecemos la cantidad de tokens a stakear (100 tokens)
        uint256 durationYears = 1; // Duración del staking: 1 año

        // Aprobar el contrato de staking para mover los tokens del usuario
        vm.prank(user);
        token.approve(address(staking), stakingAmount);

        // Realizar el staking del usuario
        vm.prank(user);
        staking.stake(stakingAmount, durationYears);

        // Obtener la información del stake del usuario
        (, uint256 startTime, ) = staking.stakes(user); // Obtenemos el 'startTime' del usuario

        // Verificar que el tiempo de inicio del staking sea mayor que 0 (es decir, se haya hecho correctamente)
        assertTrue(startTime > 0);

        // Simular el paso del tiempo para cumplir con la condición de recompensa (1 año)
        vm.warp(startTime + 365 days); // Avanzamos el tiempo 1 año desde el 'startTime'

        // Calcular la recompensa basada en el staking
        uint256 reward = staking.calculateReward(user); // Calculamos la recompensa según el tiempo de staking

        // Verificar que la recompensa sea el 25% de los tokens stakeados (100 * 25% = 25 tokens)
        assertEq(reward, (stakingAmount * 25) / 100); // Verificamos que la recompensa calculada sea correcta (25 tokens)
    }
}
