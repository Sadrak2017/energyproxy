var areaChartCanvas
var transactionhistoryChart
var areaDatas
var areaChart

atualizaMetricas(0)
atualizaMetricasPotencia(0)
function atualizaTabela(desc, id){
    $.get('/data', function(res) {
      const data = res; // Obtém os dados JSON da resposta
      const container = document.querySelector(".dropdown-menu");
      const btnModulo = document.getElementById('createbuttonDropdown');
      container.innerHTML = '';
      if(desc !== 'Selecionar Módulo' && desc !== undefined){
        btnModulo.textContent = desc;''
        document.getElementById('moduloAqui').textContent = desc;
        atualizaMetricas(id);
        atualizaMetricasPotencia(id);
      
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
            <a onclick="atualizaTabela('${item.modelo} ${item.serie}', ${item.id})" class="preview-subject ellipsis mb-1">${item.modelo} ${item.serie}</a>
          </div>
        `;
        container.appendChild(itemA);
    });
  });
}
atualizaTabela();
function atualizaMetricas(id){
  $.get('/data/metricas/'+id, function(res) {
    const data = res; // Obtém os dados JSON da resposta
    document.getElementById('dia').textContent = 'R$ '+ data[0].dia;
    document.getElementById('semana').textContent = 'R$ '+ data[0].semana;
    document.getElementById('mes').textContent = 'R$ '+ data[0].mes;
    document.getElementById('ano').textContent = 'R$ '+ data[0].ano;
    document.getElementById('moduloAnual').textContent = 'R$ '+ data[0].total;
    document.getElementById('dataAtual2').textContent = formatarData();
    if(res !== undefined && res != null && id !== 0)
      setInterval(atualizaMetricas(id), 1000);
  });
}
function formatarData() {
const data = new Date();
const meses = [
  "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
  "Jul", "Ago", "Set", "Out", "Nov", "Dez"
];

const dia = String(data.getDate()).padStart(2, "0");
const mes = meses[data.getMonth()];
const ano = data.getFullYear();
const horas = String(data.getHours()).padStart(2, "0");
const minutos = String(data.getMinutes()).padStart(2, "0");
const periodo = horas >= 12 ? "PM" : "AM";

// Converte horas para o formato 12 horas
const horas12 = horas > 12 ? horas - 12 : horas;

return `${dia} ${mes} ${ano}, ${horas12}:${minutos}${periodo}`;
}
function atualizaMetricasPotencia(id){
  var labelsX = [0];
  var dataY = [0];

  $.get('/data/metricas/potencia/'+id, function(res) {
    const data = res; // Obtém os dados JSON da resposta
    if(data !== undefined && data !== null){
      labelsX = [0];
      dataY = [0];
      data.forEach((item) => {
        labelsX.push(item.horario + 'h')
        dataY.push(item.potencia)
      });
      renderGraph(labelsX, dataY);
    }
  });
  $.get('/data/metricas/potencia/dia/'+id, function(res) {
    const data = res; // Obtém os dados JSON da resposta
    labelsX = [0];
    dataY = [0];
    if(data !== undefined && data !== null){
      data.forEach((item) => {
        labelsX.push(item.horario + 'h')
        dataY.push(item.potencia)
      });
      renderkWh(labelsX, dataY);
    }
  });
}
function renderGraph(x, y){
  var areaData = {
    labels: x,
    datasets: [{
      label: '# limpar',
      yLabel: 'Watts',
      data: y,
      backgroundColor: [
        'rgba(255, 99, 132, 0.2)',
        'rgba(54, 162, 235, 0.2)',
        'rgba(255, 206, 86, 0.2)',
        'rgba(75, 192, 192, 0.2)',
        'rgba(153, 102, 255, 0.2)',
        'rgba(255, 159, 64, 0.2)'
      ],
      borderColor: [
        'rgba(255,99,132,1)',
        'rgba(54, 162, 235, 1)',
        'rgba(255, 206, 86, 1)',
        'rgba(75, 192, 192, 1)',
        'rgba(153, 102, 255, 1)',
        'rgba(255, 159, 64, 1)'
      ],
      borderWidth: 1,
      fill: true, // 3: no fill
    }]
  };
  if ($("#areaChart").length) {
    areaChartCanvas = $("#areaChart").get(0).getContext("2d");
    areaChart = new Chart(areaChartCanvas, {
      type: 'line',
      data: areaData,
      options: areaOptions
    });
  }
  var areaOptions = {
      plugins: {
          filler: {
              propagate: false
          }
      },
      animation: {
        duration: 0, // general animation time
      },
      hover: {
          animationDuration: 0, // duration of animations when hovering an item
      },
      responsiveAnimationDuration: 0,
      responsive: true,
      scales: {
          yAxes: [{
              gridLines: {
                  color: "rgba(204, 204, 204,0.1)"
              },
              title: {
                display: true,
                text: 'kW'
            }
          }],
          
          xAxes: [{
              gridLines: {
                  color: "rgba(204, 204, 204,0.1)"
              },
              type: 'linear', // Adicione isso para escala linear no eixo x
              ticks: {
                  stepSize: 1, // Ajuste o stepSize conforme necessário
              },
          }]
      },
      legend: {
        display: true
      },
  };

}
function renderkWh(x, y){
if ($("#transaction-history").length) {
var areaDatas = {
  labels: x,
  datasets: [{
      data: y,
      backgroundColor: [
        "#111111","#00d25b","#ffab00"
      ]
    }
  ]
};
var areaOptionss = {
  responsive: false,
  maintainAspectRatio: false,
  segmentShowStroke: false,
  cutoutPercentage: 70,
  elements: {
    arc: {
        borderWidth: 0
    }
  },      
  legend: {
    display: false
  },
  tooltips: {
    enabled: true
  }
}
var transactionhistoryChartPlugins = {
  beforeDraw: function(chart) {
    var width = chart.chart.width,
        height = chart.chart.height,
        ctx = chart.chart.ctx;

    ctx.restore();
    var fontSize = 1;
    ctx.font = fontSize + "rem sans-serif";
    ctx.textAlign = 'left';
    ctx.textBaseline = "middle";
    ctx.fillStyle = "#ffffff";

    var text = y[y.length - 1], 
        textX = Math.round((width - ctx.measureText(text).width) / 2),
        textY = height / 2.4;

    ctx.fillText(text, textX, textY);

    ctx.restore();
    var fontSize = 0.75;
    ctx.font = fontSize + "rem sans-serif";
    ctx.textAlign = 'left';
    ctx.textBaseline = "middle";
    ctx.fillStyle = "#6c7293";

    var texts = "kWh", 
        textsX = Math.round((width - ctx.measureText(text).width) / 1.93),
        textsY = height / 1.7;

    ctx.fillText(texts, textsX, textsY);
    ctx.save();
  }
}
var transactionhistoryChartCanvas = $("#transaction-history").get(0).getContext("2d");
transactionhistoryChart = new Chart(transactionhistoryChartCanvas, {
  type: 'doughnut',
  data: areaDatas,
  options: areaOptionss,
  plugins: transactionhistoryChartPlugins
});
}
}