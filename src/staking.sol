// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Staking Contract
 * @notice Este contrato permite a los usuarios hacer staking de un token ERC20 durante 1, 2 o 3 años y obtener recompensas basadas en el tiempo de staking.
 */

contract Staking {
    // Estructura para almacenar los detalles del stake de cada usuario

    struct Stake {
        uint256 amount; // Cantidad de tokens en staking
        uint256 startTime; // Tiempo en que el usuario hizo staking
        uint256 duration; // Duración del staking en segundos
    }

    IERC20 public immutable token; // El token que se está stakeando
    uint constant YEAR = 365 * 24 * 60 * 60; // un año en segundos
    address public owner; // Dirección del propietario del contrato

    mapping(address => Stake) public stakes; // Mapeo para almacenar los stakes de cada usuario

    /**
     * @notice Constructor del contrato que establece el token ERC20 para staking
     * @param _token La dirección del contrato del token ERC20
     */
    constructor(IERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    /**
     * @notice Realizar staking de una cierta cantidad de tokens durante 1, 2 o 3 años
     * @param _amount La cantidad de tokens a hacer stake
     * @param _duration La duración del stake en años (1, 2 o 3)
     */
    function stake(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "El monto no es suficiente");
        require(
            _duration == 1 || _duration == 2 || _duration == 3,
            "La duracion debe ser 1, 2 o 3 anos"
        );

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "No se ha podido enviar sus tokens"
        );

        stakes[msg.sender] = Stake({
            amount: _amount,
            startTime: block.timestamp,
            duration: _duration * YEAR
        });
    }

    /**
     * @notice Retirar los tokens del stake y obtener las recompensas si se cumplen las condiciones
     */
    function unStake() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tienes tokens en staking");

        uint256 stakingTime = block.timestamp - userStake.startTime;

        if (stakingTime >= userStake.duration) {
            uint256 reward = calculateReward(msg.sender);
            uint256 totalAmount = userStake.amount + reward;

            require(
                token.transfer(msg.sender, totalAmount),
                "No se ha podido enviar sus tokens"
            );
        } else {
            require(
                token.transfer(msg.sender, userStake.amount),
                "No se ha podido devolver tus tokens"
            );
        }

        delete stakes[msg.sender];
    }

    /**
     * @notice Reclamar solo las recompensas sin retirar el stake
     */
    function claimReward() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tienes tokens en staking");

        uint256 stakingTime = block.timestamp - userStake.startTime;
        require(stakingTime >= YEAR, "El tiempo minimo de staking es 1 ano");

        uint256 reward = calculateReward(msg.sender);
        require(
            token.transfer(msg.sender, reward),
            "No se ha podido transferir tus recompensas"
        );

        //userStake.startTime = block.timestamp; // Reiniciar el tiempo de staking
        //Al reiniciar el startTime, se complica la ide de recompensas progresivas (porcentaje basado en 1, 2 o 3 años).
        // Un usuario podría recibir un “bucle infinito” de recompensas del 25%, reiniciando su staking cada vez que reclama.
    }

    /**
     * @notice Depositar tokens en el contrato para asegurar liquidez
     * @param _amount La cantidad de tokens a depositar
     */
    function ownerDeposit(uint256 _amount) external {
        require(msg.sender == owner, "Solo el propietario puede hacer esto");
        require(_amount > 0, "La cantidad debe ser mayor a cero");

        require(
            token.transferFrom(owner, address(this), _amount),
            "No se ha podido enviar sus tokens"
        );
    }

    /**
     * @notice Calcular las recompensas en función del tiempo de staking
     * @param user Dirección del usuario
     * @return La cantidad de tokens de recompensa
     */
    //Original
    // function calculateReward(address user) internal view returns (uint256) {
    //     Stake memory userStake = stakes[user];
    //     uint256 elapsedTime = block.timestamp - userStake.startTime;
    //     uint256 rewardRate = 0;

    //     if (elapsedTime >= 1 * YEAR && elapsedTime < 2 * YEAR) {
    //         rewardRate = 25; // 25% después de 1 año
    //     } else if (elapsedTime >= 2 * YEAR && elapsedTime < 3 * YEAR) {
    //         rewardRate = 50; // 50% después de 2 años
    //     } else if (elapsedTime >= 3 * YEAR) {
    //         rewardRate = 75; // 75% después de 3 años
    //     }

    //     return (userStake.amount * rewardRate) / 100;
    // }
    //Funcion de prueba
    function calculateReward(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        require(userStake.amount > 0, "User has no stake.");
        uint256 elapsedTime = block.timestamp - userStake.startTime;
        uint256 rewardRate = 0;

        if (elapsedTime >= 1 * YEAR && elapsedTime < 2 * YEAR) {
            rewardRate = 25; // 25% después de 1 año
        } else if (elapsedTime >= 2 * YEAR && elapsedTime < 3 * YEAR) {
            rewardRate = 50; // 50% después de 2 años
        } else if (elapsedTime >= 3 * YEAR) {
            rewardRate = 75; // 75% después de 3 años
        }

        return (userStake.amount * rewardRate) / 100;
    }
}
