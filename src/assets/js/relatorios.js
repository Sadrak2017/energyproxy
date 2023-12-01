function atualizaComboList(desc, id){
    $.get('/data', function(res) {
      const data = res; // Obtém os dados JSON da resposta
      const container =  document.querySelector(".dropdown-menu");
      const btnModulo = document.getElementById('createbuttonDropdown2');
      container.innerHTML = '';
      if(desc !== 'Selecionar Módulo' && desc !== undefined && desc !== "" && desc !== null){
        btnModulo.textContent = desc;
        localStorage.setItem('modeloID', id);
        localStorage.setItem('modeloDesc', desc);
        document.querySelector('.src-energy').id = id;
        document.getElementById('idModulo').value = id; 
        $("#elements").toggleClass("show");
        atualizaTabela(id);
      }
      // Itera sobre os dados e cria uma linha (<tr>) para cada registro
      data.forEach((item) => {
        // Seletor do container onde você deseja adicionar os módulos
        const itemA = document.createElement("a");
        itemA.classList.add("dropdown-item", "preview-item");
        itemA.innerHTML = `
          <div class="preview-thumbnail">
            <div class="preview-icon bg-dark rounded-circle">
              <i class="mdi mdi-layers text-danger"></i>
            </div>
          </div>
          <div class="preview-item-content">
            <a onclick="atualizaComboList('${item.modelo} ${item.serie}', ${item.id})" class="preview-subject ellipsis mb-1">${item.modelo} ${item.serie}</a>
          </div>
        `;
        container.appendChild(itemA);
      });
    });
  } 
  atualizaComboList(localStorage.getItem('modeloDesc'), localStorage.getItem('modeloID'));
  $("#elements").toggleClass("show");
  function buscaDadosCarga(id){
      if (id !=="" && id !== undefined){
        $.get('/data/carga/cf/'+id, function(res) {  
          const data = res; 
          document.getElementById('potMin').value = data[0].potmin;
          document.getElementById('potMax').value = data[0].potmax;
          document.getElementById('cargalabel').innerHTML = data[0].slot !== null ? 'Carga conectada '+ data[0].slot : 'Nenhuma carga conectada';   
        })
      }
    }
  function atualizaTabela(id){
    if (id !=="" && id !== undefined) {
      buscaDadosCarga(id);
      $.get('/data/classificacao/'+id, function(res) {
        const data = res; // Obtém os dados JSON da resposta
        
        const tableBody = document.getElementById('table-body'); // Obtém o tbody da tabela

        // Limpa qualquer conteúdo existente na tabela
        tableBody !== undefined ? tableBody.innerHTML = '' : undefined;
        // Itera sobre os dados e cria uma linha (<tr>) para cada registro
        data.forEach((item) => {
          const row = document.createElement('tr'); // Cria uma nova linha
          // Cria células (<td>) para cada coluna
          const IDCell = document.createElement('td');
          IDCell.textContent = item.id;
          // Cria células (<td>) para cada coluna
          const cargaCell = document.createElement('td');
          cargaCell.textContent = item.carga;

          const potMinCell = document.createElement('td');
          let min = Math.round(item.potmin * 10000) / 10000;
          potMinCell.textContent = min.toFixed(4).replace('.', ',');

          let max = Math.round(item.potmax * 10000) / 10000;
          const potMaxCell = document.createElement('td');
          potMaxCell.textContent = max.toFixed(4).replace('.', ',');
          
          let con = Math.round(item.consumo * 10000) / 10000;
          const consumoCell = document.createElement('td');
          consumoCell.textContent = con.toFixed(4).replace('.', ',');
          
          let kwh = Math.round(item.kwh * 10000) /10000;
          const kwhCell = document.createElement('td');
          kwhCell.textContent = kwh.toFixed(4).replace('.', ',');

          const slotCell = document.createElement('td');
          slotCell.textContent = item.slot;

          const statusCargaCell = document.createElement('td');
          statusCargaCell.innerHTML = item.statuscarga == 2 ? '<div class="badge badge-outline-warning">Desligado</div>' : '<div class="badge badge-outline-success">Ligado</div>';

          const dataCell = document.createElement('td');
          dataCell.textContent = item.dtinc; // Certifique-se de que o nome da coluna corresponda ao nome real

          // Adiciona as células à linha
          row.appendChild(IDCell);
          row.appendChild(cargaCell);
          row.appendChild(potMinCell);
          row.appendChild(potMaxCell);
          row.appendChild(kwhCell); 
          row.appendChild(consumoCell);
          row.appendChild(slotCell);
          row.appendChild(statusCargaCell);
        // row.appendChild(dataCell);
        
          // Adiciona a coluna de ações com o botão "Excluir"
          const acoesCol = document.createElement('td');
          const excluirBtn = document.createElement('button');
          excluirBtn.textContent = 'Excluir';
          excluirBtn.classList.add('btn', 'btn-danger');
          excluirBtn.addEventListener('click', () => excluirCarga(item.id)); // Assuma que `modulo.id` contém o ID do módulo
          acoesCol.appendChild(excluirBtn);
          row.appendChild(acoesCol);

          tableBody.appendChild(row);
        });
      });
    }  
  }
  async function excluirCarga(id) {
    if (confirm('Tem certeza que deseja excluir a carga com ID ' +id+' ?')) {
      try {
        const response = await fetch(`/excluir-carga/${id}`, { method: 'DELETE' });
        
        if (response.status === 200) {
          atualizaTabela(); // Atualiza a tabela após a exclusão
        } else {
          alert('Erro ao excluir carga.');
        }
      } catch (error) {
        console.error('Erro ao excluir carga:', error);
      }
    }
  }
  function simularClique() {
    document.getElementById('btnUpdate').click();
  }
  function simularClique2() {
    document.getElementById('btnUpdateGravar').click();
  }
  $(document).ready(function() {
    $("#createbuttonDropdown2").on("click", function() {
      $("#elements").toggleClass("show");
    });
  });
  $(document).ready(function() {
    // Adiciona um evento de clique ao botão "Gravar uma nova carga"
    $("#gravarCarga").on("click", function() {
      // Abre o modal com ID "modalCadastro"
      $("#modalCadastro").modal("show");
    });
  });
  setInterval(simularClique2, 1000);
  setInterval(simularClique, 1000);
  atualizaTabela();