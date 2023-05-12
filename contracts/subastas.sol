// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./NFTs.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Subasta {

    NFT public nftContract;

    //Eventos para notificar a los usuarios sobre las subastas
    event NuevaSubasta(uint256 subastaId, address creador);
    event NuevaOferta(uint256 subastaId, address apostador, uint256 cantidad);
    event SubastaFinalizada(uint256 subastaId, address ganador, uint256 cantidad);

    //Struct de una subasta
    struct subasta {
        uint256 idSubasta;
        address nftContract;
        address creador;
        string nombreArticulo;
        uint256 idNFT;
        string descripcion;
        uint256 precioActual;
        uint256 duracion;
        uint256 finalizacion;
        address ganador;
        bool finalizada;
    }

    //Lista subastas 
    mapping(uint256 => subasta) public subastas;

    //Lista NFT
    mapping (uint256 => NFT) private nfts;
    
    uint256 tokenCounter = 0;
    uint256 idSubasta = 0;

    function getOwner(uint256 _idSubasta) public view returns (address){
        return nfts[_idSubasta].getOwnerOfNFT(subastas[_idSubasta].idNFT);
    }

    //Funcion para iniciar una nueva subasta
    function iniciarSubasta(string memory _nombreArticulo, string memory _simboloArticulo,
     string memory _descripcion, uint256 _precioInicial, uint256 _duracion) public returns (subasta memory){

            //Craer el NFT
            nftContract = new NFT(_nombreArticulo, _simboloArticulo);
            nftContract.createNFT(address(this), tokenCounter);
            nfts[idSubasta] = nftContract;

            //Almacenamos los datos de la subasta en una nueva estructura de la subasta
            subasta memory nuevaSubasta = subasta({
                idSubasta: idSubasta,
                nftContract: address(nftContract),
                creador: msg.sender,
                nombreArticulo: _nombreArticulo,
                idNFT: tokenCounter,
                descripcion: _descripcion,
                precioActual: _precioInicial,
                duracion: _duracion,
                finalizacion: block.timestamp + _duracion,
                ganador: address(0),
                finalizada: false
            });

            //Agregar subasta al mapping de subastas
            subastas[idSubasta] = nuevaSubasta;

            //Evento de una nueva subasta
            emit NuevaSubasta(idSubasta, msg.sender);
            idSubasta = idSubasta + 1;

            tokenCounter = tokenCounter + 1;

            return nuevaSubasta;
        }

        //Función para realizar una oferta
        function apostar(uint256 _subastaId) public payable {
            //Comprobar de que la subasta este en curso
            require(block.timestamp < subastas[_subastaId].finalizacion, "La subasta ha finalizado");
            //Comprobar que se supera la apuesta actual
            require(msg.value > subastas[_subastaId].precioActual, "La apuesta debe ser superior al precio actual");

            //Devolver el dinero al usuario que iba ganando la subasta
            if(subastas[_subastaId].ganador != address(0)){
                payable(subastas[_subastaId].ganador).transfer(subastas[_subastaId].precioActual);
            }

            //Actualizar la apuesta actual y el ganador actual
            subastas[_subastaId].precioActual = msg.value;
            subastas[_subastaId].ganador = msg.sender;

            emit NuevaOferta(_subastaId, msg.sender, msg.value);
        }

        function finalizacionSubasta(uint256 _idSubasta) public payable {
            //El id de la subasta que se recibe por parametros sea menor igul al contador de idSubasta
            require(_idSubasta <= idSubasta);
            //Solo el creador de la subasta puede llamar a la funcion finalizar
            require(msg.sender == subastas[_idSubasta].creador);
            //Comprobar que la subasta no este en curso
            require(block.timestamp > subastas[_idSubasta].finalizacion, "La subasta no ha finalizado");
            

            //Paga el ganador al creador de la subasta
            payable (subastas[_idSubasta].ganador).transfer(subastas[_idSubasta].precioActual);

            //Enviar NFT al ganador
            nfts[_idSubasta].transferNFT(address(this), subastas[_idSubasta].ganador, subastas[_idSubasta].idNFT);
            
            //Emitir subasta finalizada
            emit SubastaFinalizada( _idSubasta, subastas[_idSubasta].ganador, subastas[_idSubasta].precioActual);

            subastas[_idSubasta].finalizada = true;
            
            
        }
}
